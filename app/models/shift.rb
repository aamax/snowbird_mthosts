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

# if shift status = -1   ->  missed shift

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

  default_scope :order => "shift_date asc, shift_type_id asc", :conditions => "shift_date >= '#{Date.new(2013,9,1)}'"
  scope :last_year, where("shifts.shift_date < '#{Date.new(2013,9,1)}'").order("shifts.shift_date")
  scope :currentuser, lambda{|userid| where :user_id => userid}
  scope :assigned, where("shifts.user_id is not null").order("shifts.shift_date")
  scope :un_assigned, where("shifts.user_id is null").order("shifts.shift_date")

  # shift status values:
  #      worked = 1
  #      pending = 1
  #      missed = -1
  scope :currentuserworked, lambda{ |userid| where("user_id = #{userid} and shift_status = 1 and shift_date <= #{Date.today}")}
  scope :currentuserpending, lambda{|userid| where("user_id = #{userid} and shift_status = 1 and shift_date > #{Date.today}") }
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

  def short_name
    self.shift_type.short_name[0..1]
  end

  def shadow?
    self.short_name[0..1] == "SH"
  end

  def team_leader?
    self.short_name[0..1] == "TL"
  end

  def round_one_rookie_shift?
    ['G1','G2','G3','G4','C3','C4'].include? self.short_name
  end

  def standard_shift?
    ['P1', 'P2', 'P3', 'P4', 'C1', 'C2', 'G5', 'G6', 'G7', 'G8', 'TL'].include? self.short_name[0..1]
  end

  def can_select(test_user)
    retval = false
    if self.user_id.nil?
      # if user is already working this day
      rookie_training_shifts = []
      shadow_shifts = []
      max_shadow_date = nil
      max_rookie_shift_date = nil
      bingo_start = SysConfig.first.bingo_start_date
      round = get_current_round(bingo_start, Date.today, test_user)

      if self.team_leader?
        return test_user.team_leader? ? true : false
      end

      if !test_user.rookie? && (round == 0)
        return false
      end

      return false if self.shadow? && !test_user.rookie?

      test_user.shifts.each do |s|
        if s.shift_date == self.shift_date
          return false
        end
        if test_user.rookie?
          if s.shadow?
            shadow_shifts << s
            max_shadow_date = s.shift_date if (max_shadow_date.nil? || (s.shift_date > max_shadow_date))
          end
          if s.round_one_rookie_shift?
            rookie_training_shifts << s
            max_rookie_shift_date = s.shift_date if (max_rookie_shift_date.nil? || (s.shift_date > max_rookie_shift_date))
          end
        end
      end

      if test_user.rookie?
        if (self.shadow?)
          return false if shadow_shifts.count >= 2
        else
          return false if shadow_shifts.count < 2

          if rookie_training_shifts.count < 5
            return false if (self.shift_date <= max_shadow_date) || (!self.round_one_rookie_shift?)
          end

          # if round one or less then no more than 7 shifts selected for rookies
          if round <= 1
            return false if (rookie_training_shifts.count == 5)
          end
        end
      else
        if round < 5
          # if pre bingo - return false
          return false if round <= 0
          return false if (test_user.shifts.count >= (round * 5))
        end
      end







      retval = true
    end
    retval
  end

  # 0..1 group 3 round 1
  # 2..3 group 2 round 1
  # 4..5 group 1 round 1

  # 6..7 group 3 round 2
  # 8..9 group 2 round 2
  # 10..11 group 1/rookie round 2


  def get_current_round(bingo_start, dt, usr)
    return 0 if dt < bingo_start

    day_count = (dt - bingo_start).to_i
    round_num = (day_count / 6).to_i + 1
    group_num = (day_count % 6).to_i

    return round_num if usr.group_3?
    return round_num if usr.group_2? && (group_num >= 2)
    return round_num if (usr.group_1? || usr.rookie?) && (group_num >= 4)
    return (round_num - 1)
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
