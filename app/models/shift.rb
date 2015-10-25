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

  before_save :set_day_of_week, :set_short_name

  belongs_to :user
  belongs_to :shift_type

  date_regex = /\A(19|20)\d\d[. -\/](0[1-9]|1[012])[. -\/](0[1-9]|[12][0-9]|3[01])\z/

  validates   :shift_type_id,  :presence => true

  validates :shift_date, :presence => true,
            :format => { :with => date_regex }

  #default_scope :order => "shift_date asc, shift_type_id asc", :conditions => "shift_date >= '#{HostConfig.season_start_date}'"

  default_scope {
    order("shift_date asc, shift_type_id asc")
    where("shift_date >= '#{HostConfig.season_start_date}'")
  }

  scope :last_year, -> {
    where("shifts.shift_date < '#{HostConfig.season_start_date}'").order("shifts.shift_date")
  }
  scope :currentuser, lambda{|userid| where :user_id => userid}
  scope :assigned,-> {
      where("shifts.user_id is not null").order("shifts.shift_date")
  }
  scope :un_assigned, -> {
    where("shifts.user_id is null").order("shifts.shift_date")
  }
  scope :team_leader_shifts, -> {
    where("shifts.shift_type_id = #{ShiftType.team_lead_type.id}")
  }

  # shift status values:
  #      worked = 1
  #      pending = 1
  #      missed = -1
  scope :currentuserworked, lambda{ |userid| where("user_id = #{userid} and shift_status = 1 and shift_date <= #{Date.today}")}
  scope :currentuserpending, lambda{|userid| where("user_id = #{userid} and shift_status = 1 and shift_date > #{Date.today}") }
  scope :currentusermissed, lambda{|userid| where :user_id => userid, :shift_status => -1}
  scope :distinctDates, -> {
    where('distinct on (shift_date) shift_date, shift_type_id')
  }

  def self.assign_team_leaders(params)
    days = {'monday' => 1, 'tuesday' => 2, 'wednesday' => 3, 'thursday' => 4, 'friday' => 5, 'saturday' => 6, 'sunday' => 7}
    params.each do |day_str, user_name|
      next if days[day_str].nil?
      user = User.find_by_name(user_name)
      unless user.nil?
        shifts = Shift.team_leader_shifts.to_a.delete_if {|shift| !shift.user_id.nil? || shift.shift_date.cwday != days[day_str] }
        shifts.each do |s|
          s.user_id = user.id
          s.save
        end
      end
    end
  end

  def self.by_day_of_week(days)
    return scoped unless days.present?
    where(:day_of_week => days)
  end

  def self.by_holidays(flag)
    return scoped unless flag == true
    where("shift_date in ('#{HOLIDAYS.join("','")}')")
  end

  def self.by_unselected(flag)
    return scoped unless flag == true
    where("user_id is null")
  end

  def self.by_shift_type(sts)
    return scoped unless sts.present?
    types = []

    ShiftType.all.each do |st|
      if sts.include? st.abbreviated_name
        types << st
      end
    end

    return scoped if types.nil? || (types.length == 0)
    where("shift_type_id in (#{types.map {|t| t.id}.join(',')})")
  end

  def self.by_date(dt)
    return scoped unless dt.present?

    where(:shift_date => dt)
  end

  def self.by_users(users)
    return scoped unless users.present?

    dates = []
    user_list = User.find_all_by_name(users)
    user_list.each do |u|
      u.shifts.each do |s|
        dates << s.shift_date.strftime("%Y-%m-%d")
      end
    end
    dates.uniq
    return where("shift_date is null") if dates.length == 0
    where("shift_date in ('#{dates.join("','")}')")
  end

  def self.with_meetings(flag)
    return scoped if flag == true
    return where("shift_type_id not in (#{types.join(',')})") if flag.nil?

    types = ShiftType.where("short_name in ('M1', 'M2', 'M3', 'M4')").map {|st| st.id }

    return scoped if (types.nil? || (types.length == 0))
    where("shift_type_id not in (#{types.join(',')})")

  end

  def self.from_today(ft)
    return scoped unless ft == true
    where("shift_date >= '#{Date.today}'")
  end

  def status_string
    value = "Worked" if ((self.shift_status_id != -1) && (self.shift_date <= Date.today))
    value = "Pending" if ((self.shift_status_id != -1) && (self.shift_date > Date.today))
    value ||= "Missed"
    value
  end

  def date
    shift_date
  end

  def status_operation
    self.shift_status_id == -1 ? value = "Missed" : value = "Worked"
    value
  end

  # def short_name
  #   self.shift_type.short_name[0..1]
  # end

  def full_short_name
    self.shift_type.short_name
  end

  def type_suffix
    self.shift_type.short_name[2..-1]
  end

  def shadow?
    self.short_name[0..1] == "SH"
  end

  def team_leader?
    (self.short_name[0..1] == "TL") || (self.shift_type.short_name.downcase == 'p2weekday')
  end

  def trainer?
    (self.short_name[0..1] == "TR")
  end

  # TODO remove commented routine
  # def round_one_rookie_shift?
  #   retval = ['G1','G2', 'G3','G4', 'C3', 'C4'].include?(self.short_name)
  #   if retval == true
  #     retval = false if (self.full_short_name.downcase == 'g3friday') || (self.full_short_name.downcase == 'g4friday')
  #   end
  #   return retval
  # end

  def meeting?
    self.short_name[0] == 'M'
  end

  # TODO remove commented routine
  # def standard_shift?
  #   ['P1', 'P2', 'P3', 'P4', 'C1', 'C2', 'G5', 'G6', 'G7', 'G8', 'TL'].include? self.short_name
  # end

  # TODO remove commented routine
  # def trainee_can_pick?
  #   suffix = self.type_suffix.downcase
  #   return false unless ((suffix.include? 'weekend') || (suffix.include? 'friday'))
  #
  #   users = self.users_on_date.to_a.delete_if {|u| !u.is_trainee_on_date(self.shift_date)}
  #   return false if !self.round_one_rookie_shift?
  #   true
  # end

  def users_on_date
    Shift.where(:shift_date => self.shift_date).to_a.delete_if {|s| s.short_name == 'SH' }.map {|s| s.user }.to_a.delete_if {|u| u.nil? }
  end

  def can_select(test_user)
    retval = false
    if self.user_id.nil?
      # if user is already working this day
      return false if test_user.is_working?(self.shift_date)
      return true if test_user.admin?
      return false if self.shadow? && !test_user.rookie?
      return false if !test_user.team_leader? && self.team_leader?
      return false if self.trainer? && !test_user.trainer?

      bingo_start = HostConfig.bingo_start_date
      round = HostUtility.get_current_round(bingo_start, Date.today, test_user)
      shift_count = test_user.shifts.to_a.delete_if {|s| s.trainer? }.count

      if test_user.team_leader?
        if round <= 4
          return false if shift_count >= 20
        end
      elsif test_user.rookie?
        return false if !self.shadow? && (test_user.last_shadow.nil? || (self.shift_date < test_user.last_shadow))

        shadow_count = test_user.shadow_count
        if (shadow_count < SHADOW_COUNT)
          return false if !self.shadow?
          return true
        else
          if round < 5
            return false if (round <= 0) && (shift_count >= 5)
            return false if (shift_count >= (round * 5)) & (round > 0)
            return false if (round == 4) && (shift_count >= 20)
          end
        end
      else
        if round < 5
          # if pre bingo - return false
          return false if round <= 0

          return false if (shift_count >= (round * 5))
          return false if (round <= 4) && (shift_count >= 20)
        end
      end
      retval = true



    #
    #   if test_user.rookie?
    #     shadow_count = test_user.shadow_count
    #     if (self.shadow?)
    #       return false if shadow_count >= 2
    #       round_one_shift_count = test_user.round_one_type_count
    #       return false if (round_one_shift_count > 0) && (test_user.first_round_one_end_date <= self.shift_date)
    #     else
    #       return false if (shadow_count < 2)
    #
    #       max_shadow_date = test_user.last_shadow
    #       return false if (max_shadow_date >= self.shift_date)
    #
    #       return false if (shift_count >= (round * 5 + 2) && round > 0 && round < 3)
    #       return false if round.between?(3,4) && (shift_count >= 16)
    #       return false if (round == 0) && (shift_count >= 7)
    #
    #       round_one_shift_count = test_user.round_one_type_count
    #
    #       if round_one_shift_count < 5
    #         return false if (self.shift_date <= max_shadow_date)
    #         return false if (!self.round_one_rookie_shift?)
    #
    #         first_non_round_one_date = test_user.first_non_round_one_end_date
    #         return false if (!first_non_round_one_date.nil? && (self.shift_date >= first_non_round_one_date))
    #
    #         shifts_on_date = Shift.where(shift_date: self.shift_date).to_a.delete_if {|s| s.user.nil? || s.user.is_trainee_on_date(self.shift_date)}
    #
    #         return false if shifts_on_date.length >= 3
    #
    #         training_shift_types = shifts_on_date.map {|s| s.short_name }
    #         if short_name == 'G1'
    #           return false if training_shift_types.include? 'G2'
    #         elsif short_name == 'G2'
    #           return false if training_shift_types.include? 'G1'
    #         elsif short_name == 'G3'
    #           return false if training_shift_types.include? 'G4'
    #         elsif short_name == 'G4'
    #           return false if training_shift_types.include? 'G3'
    #         elsif short_name == 'C3'
    #           return false if training_shift_types.include? 'C4'
    #         elsif short_name == 'C4'
    #           return false if training_shift_types.include? 'C3'
    #         end
    #       else
    #         return false if (!self.round_one_rookie_shift?) && (test_user.round_one_end_date > self.shift_date)
    #       end
    #
    #       return false if (!self.round_one_rookie_shift? && (self.shift_date <= test_user.round_one_end_date))
    #
    #       # TODO remove commented
    #       # if test_user.is_trainee_on_date(self.shift_date)
    #       #   return self.trainee_can_pick?
    #       # end
    #     end
    #   else
    #     if round < 5
    #       # if pre bingo - return false
    #       return false if round <= 0
    #
    #       return false if (shift_count >= (round * 5))
    #       return false if (round <= 4) && (test_user.shifts.count >= 18)
    #     end
    #   end
    #   retval = true
    # else
    #   return false
    end



    retval
  end

  def can_drop(current_user)
    return false if self.user_id.nil?
    return false if self.short_name[0] == "M"
    return true if current_user.has_role? :admin
    return false if self.shift_date < Date.today()
    return false if current_user.id != self.user_id
    return false if self.shift_date <= Date.today + 13.days

    true
  end

  def user_name
    self.user.name
  end

  private
  def set_day_of_week
    self.day_of_week = self.shift_date.strftime("%a")
  end

  def set_short_name
    self.short_name = self.shift_type.short_name[0..1].upcase
  end

end
