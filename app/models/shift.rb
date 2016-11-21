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
#  short_name      :string
#

# if shift status = -1   ->  missed shift

class Shift < ActiveRecord::Base
  attr_accessible :user_id, :shift_type_id, :shift_status_id, :shift_date, :day_of_week, :user_can_select
  attr_accessor :user_can_select

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
      if sts.include? st.short_name
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

  def is_tour?
    ['P1','P2','P3','P4'].include? self.short_name
  end
  
  def shadow?
    self.short_name == "SH"
  end

  def team_leader?
    (self.short_name == "TL") || (self.shift_type.short_name.downcase == 'p2weekday')
  end

  def trainer?
    (self.short_name == "TR")
  end

  def rookie_training_type?
    ['G1','G2','G3','G4','C1','C2','C3','C4','H1','H2', 'H3', 'H4'].include? self.short_name
  end

  def meeting?
    self.short_name[0] == 'M'
  end

  def users_on_date
    Shift.where(:shift_date => self.shift_date).to_a.delete_if {|s| s.short_name == 'SH' }.map {|s| s.user }.to_a.delete_if {|u| u.nil? }
  end

  def can_select(test_user)
    retval = false
    if self.user_id.nil?
      all_shifts =  test_user.shifts.to_a
      working_shifts =  test_user.shifts.to_a.delete_if {|s| s.meeting? }

      return false if test_user.is_working?(self.shift_date, working_shifts)
      return true if test_user.admin?
      return false if self.shadow? && !test_user.rookie?
      return false if self.team_leader? && !test_user.team_leader?
      return false if self.trainer? && !test_user.trainer?

      bingo_start = HostConfig.bingo_start_date
      round = HostUtility.get_current_round(bingo_start, Date.today, test_user)
      shift_count = working_shifts.count

      return false if (round <= 4) && (all_shifts.count >= 20)
      return true if test_user.team_leader?
      return false if (round <= 0) && (!test_user.rookie? && !test_user.trainer?)

      if test_user.rookie?
        last_shadow = test_user.last_shadow(working_shifts)
        return false if !self.shadow? && (last_shadow.nil? || (self.shift_date < last_shadow))

        shadow_count = test_user.shadow_count(working_shifts)
        if (shadow_count < SHADOW_COUNT)
          return false if !self.shadow?
          return true
        else
          return false if self.shadow?
          return false if (round < 3) && !self.rookie_training_type?
          return false if (round <= 0) && (all_shifts.count >= 9)

          if round < 5
            return false if ((shift_count) >= (round * 5)) && (round > 0)
            return false if (round == 4) && (all_shifts.count >= 20)
          end

          unless self.rookie_training_type?
            return false if test_user.not_done_training(self.shift_date, working_shifts)
          end
        end
      else
        if round < 5
          if test_user.trainer?
            return false if all_shifts.count >= 20
            return true if self.trainer?
            non_trainer_shift_count = working_shifts.delete_if {|s| s.trainer? }.count
            return false if (non_trainer_shift_count >= (round * 5))
          else
            return false if (shift_count >= (round * 5))
          end
        end
      end
      retval = true

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

  def self.get_shifts_for_index(current_user, return_params, form_filters, is_admin)
    return_params['start_from_today'] = (form_filters['start_from_today'] == '1')
    return_params['show_shifts_expanded'] = (form_filters['show_expanded'] == '1')
    return_params['show_only_unselected'] = (form_filters['show_unselected'] == '1')
    return_params['show_only_holidays'] = (form_filters['holiday_shifts'] == '1')
    return_params['include_meeting_shifts'] = (form_filters['show_meetings'] == '1')
    return_params['show_only_shifts_i_can_pick'] = (form_filters['shifts_i_can_pick'] == '1')
    return_params['shift_types_to_show'] = form_filters['shifttype'].reject{ |e| e.empty? } unless form_filters['shifttype'] == ''
    return_params['days_of_week_to_show'] = form_filters['dayofweek'].reject{ |e| e.empty? }
    return_params['hosts_to_show'] = form_filters['hosts'].reject{ |e| e.empty? } if form_filters['hosts']
    return_params['date_set_to_show'] = form_filters['date']
    return_params['date_for_calendar'] = form_filters['date'].empty? ? Date.today.strftime("%Y-%m-%d") : form_filters['date']


    @shifts = Shift.from_today(return_params['start_from_today']).with_meetings(return_params['include_meeting_shifts'])
    @shifts = @shifts.by_holidays(return_params['show_only_holidays'])
    @shifts = @shifts.by_shift_type(return_params['shift_types_to_show']).by_date(return_params['date_set_to_show'])
    @shifts = @shifts.by_day_of_week(return_params['days_of_week_to_show']).by_users(return_params['hosts_to_show'])
    @shifts = @shifts.by_unselected(return_params['show_only_unselected'])

    return_params['selectable_shifts'] = {}
    @shifts.each do |shift|
      return_params['selectable_shifts'][shift.id] = "1" if shift.can_select(current_user)
    end

    if return_params['show_only_shifts_i_can_pick'] == true
      if return_params['selectable_shifts'].count == 0
        @shifts = @shifts.where('id = 0')
      else
        @shifts = @shifts.where("id in (#{return_params['selectable_shifts'].keys.join(',')})")
      end
      @shifts = @shifts.includes(:shift_type).order(:shift_date, :short_name)
    else
      @shifts = @shifts.includes(:user).includes(:shift_type).order(:shift_date, :short_name)
    end
    
    @shifts
  end



  private
  def set_day_of_week
    self.day_of_week = self.shift_date.strftime("%a")
  end

  def set_short_name
    self.short_name = self.shift_type.short_name[0..1].upcase
  end

end
