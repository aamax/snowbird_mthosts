# == Schema Information
#
# Table name: shifts
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  shift_type_id   :integer          not null
#  shift_status_id :integer          default(1), not null
#  shift_date      :date
#  day_of_week     :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Shift < ActiveRecord::Base
  attr_accessible :user_id, :shift_type_id, :shift_status_id, :shift_date, :day_of_week
  attr_accessor :can_select#, :shift_type_short_name, :shift_type_description

  before_save :set_day_of_week


  belongs_to :user
  belongs_to :shift_type

  date_regex = /^(19|20)\d\d[. -\/](0[1-9]|1[012])[. -\/](0[1-9]|[12][0-9]|3[01])$/

  validates   :shift_type_id,  :presence => true

  validates :shift_date, :presence => true,
            :format => { :with => date_regex }

  default_scope :order => "shift_date asc, shift_type_id asc", :conditions => "shift_date >= '#{SysConfig.first.season_start_date}'"
  scope :last_year, where("shifts.shift_date < '#{SysConfig.first.season_start_date}'").order("shifts.shift_date")
  scope :currentuser, lambda{|userid| where :user_id => userid}

  # shift status values:
  #      worked = 1
  #      pending = 1
  #      missed = -1
  # TODO fix for scope usage in shift reporting...
  #scope :currentuserworked, lambda{ |userid| where :user_id => userid, :shift_status => 1}.where("shift_date <= #{Date.today}")
  #scope :currentuserpending, lambda{|userid| where  :user_id => userid, :shift_status => 1}.where("shift_date > #{Date.today}")
  scope :currentusermissed, lambda{|userid| where :user_id => userid, :shift_status => -1}
  scope :distinctDates, :select => ('distinct on (shift_date) shift_date, shift_type_id')

  def status_string
    value = "Worked" if ((self.shift_status_id == 1) && (self.shift_date <= Date.today))
    value = "Pending" if ((self.shift_status_id == 1) && (self.shift_date > Date.today))
    value ||= "Missed"
    value
  end

  def date
    shift_date
  end

  def status_operation
    self.shift_status_id == 1 ? value = "Missed" : value = "Worked"
    value
  end

  def shadow?
    self.shifttype.shortname[0..1] == "SH"
  end

  def team_leader?
    self.shifttype.shortname[0..1] == "TL"
  end

  def round_one_rookie_shift?
    ['G1','G2','G3','G4','C3','C4'].include? self.shifttype.shortname[0..1]
  end

  def standard_shift?
    ['P1', 'P2', 'P3', 'P4', 'C1', 'C2', 'G5', 'G6', 'G7', 'G8', 'TL'].include? self.shifttype.shortname[0..1]
  end

  def can_select(current_user)
    retval = false
    if self.user_id.nil?
      # TODO add logic for shift selection bingo here...

      retval = true
    end
    retval
  end

  def can_drop(current_user)
    retval = false
    unless self.user_id.nil?
      if (current_user.has_role? :admin)
        retval = true
      elsif ((current_user.id == self.user_id) && (self.shift_date > Date.today + 13.days))
        retval = true
      end
    end
    retval
  end


  private
  def set_day_of_week
    self.day_of_week = self.shift_date.strftime("%a")
  end

end
