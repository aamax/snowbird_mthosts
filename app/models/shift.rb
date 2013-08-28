class Shift < ActiveRecord::Base
  attr_accessible :user_id, :shifttype_id, :shift_status, :shift_date, :dayofweek
  attr_accessor :can_select

  before_save :perform_before_save


  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  belongs_to :shifttype, :class_name => "Shifttype", :foreign_key => "shifttype_id"

  date_regex = /^(19|20)\d\d[. -\/](0[1-9]|1[012])[. -\/](0[1-9]|[12][0-9]|3[01])$/

  validates   :shifttype_id,  :presence => true

  validates :shift_date, :presence => true,
            :format => { :with => date_regex }

  default_scope :order => "shift_date asc, shifttype_id asc", :conditions => "shift_date >= '#{SEASON_START}'"
  scope :last_year, where("shifts.shift_date < '#{SEASON_START}'").order("shifts.shift_date")



  scope :currentuser, lambda{|userid| where :user_id => userid}

  # shift status values:
  #      worked = 1
  #      pending =
  #      missed = -1

  scope :currentuserworked, lambda{ |userid| where :user_id => userid,
                                                   :shift_status => 1 }

  scope :currentuserpending, lambda{|userid| where  :user_id => userid,
                                                    :shift_status => 1}

  scope :currentusermissed, lambda{|userid| where :user_id => userid,
                                                  :shift_status => -1}

  scope :distinctDates, :select => ('distinct on (shift_date) shift_date, shifttype_id')

  def status_string
    if self.shift_status == 1
      value = "Worked"
      if (self.shift_date > Date.today)
        value = "Pending"
      end
    else
      value = "Missed"
    end
    value
  end

  def date
    shift_date
  end

  def status_operation
    if self.shift_status == 1
      value = "Missed"
    else
      value = "Worked"
    end
    value
  end

  def shadow?
    self.shifttype.shortname[0..1] == "SH"
  end

  def team_leader?
    self.shifttype.shortname[0..1] == "TL"
  end

  def round_one_rookie_shift?
    @allowed_types = ['G1','G2','G3','G4','C3','C4']
    @allowed_types.include? self.shifttype.shortname[0..1]
  end

  def standard_shift?
    @allowed_types = ['P1', 'P2', 'P3', 'P4', 'C1', 'C2', 'G5', 'G6', 'G7', 'G8', 'TL']
    @allowed_types.include? self.shifttype.shortname[0..1]
  end

  private
  def perform_before_save
    self.dayofweek = self.shift_date.strftime("%a")
    if self.shift_status.nil?
      self.shift_status = 1
    end
    endend
