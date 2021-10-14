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
#  disabled        :boolean
#

# if shift status = -1   ->  missed shift


class Shift < ActiveRecord::Base
  attr_accessible :user_id, :shift_type_id, :shift_status_id, :shift_date, :day_of_week, :user_can_select
  attr_accessor :user_can_select

  before_save :set_day_of_week, :set_short_name


  belongs_to :user
  belongs_to :shift_type
  has_many :shift_logs

  date_regex = /\A(19|20)\d\d[. -\/](0[1-9]|1[012])[. -\/](0[1-9]|[12][0-9]|3[01])\z/

  validates   :shift_type_id,  :presence => true

  validates :shift_date, :presence => true,
            :format => { :with => date_regex }

  #default_scope :order => "shift_date asc, shift_type_id asc", :conditions => "shift_date >= '#{HostConfig.season_start_date}'"

  default_scope {
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
    where("shifts.shift_type_id in (#{ShiftType.team_lead_type.map(&:id).join(',')})")
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

  def self.sort_value(shift)

  end

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

  def day_and_date
    "#{self.day_of_week} #{self.date}"
  end

  def status_operation
    self.shift_status_id == -1 ? value = "Missed" : value = "Worked"
    value
  end

  def full_short_name
    self.shift_type.short_name
  end

  def type_suffix
    self.shift_type.short_name[2..-1]
  end

  def is_tour?
    !/(P[1-4]|ST)/.match(self.short_name).nil?
    #['P1','P2','P3','P4','ST'].include? self.short_name
  end

  def team_leader?
    (self.short_name == "TL")
  end

  def trainer?
    (self.short_name == "TR")
  end

  def survey?
    (self.short_name == "SV")
  end

  def on_call?
    (self.short_name == 'OC')
  end

  def training?
    !/T[1-4]/.match(self.short_name).nil?
  end

  def meeting?
    !/M[1-4]/.match(self.short_name).nil?
  end

  def users_on_date
    Shift.where(:shift_date => self.shift_date).to_a.delete_if {|s| s.short_name == 'SH' }.map {|s| s.user }.to_a.delete_if {|u| u.nil? }
  end

  # TODO - need to re-implement all can_select logic base on new year rules etc.
  def can_select(test_user, select_params)
    retval = false
    return false if (self.shift_date < Date.today) && !test_user.has_role?(:admin)
    return false if disabled?

    if self.user_id.nil?
      return true if test_user.admin?
      return false if test_user.is_working?(self.shift_date)
      return false if self.team_leader? && !test_user.team_leader?


      return true



      # commented out all bingo code on 12/27 to remove filtering based on shift type etc
      # as per John
      # round = select_params[:round]
      #
      # return false if (round <= 0) && !test_user.team_leader?
      # all_shifts =  select_params[:all_shifts] #test_user.shifts.to_a
      # return false if ((round <= 4) && (all_shifts.count >= (round * 5) + 2)) && !test_user.team_leader?
      # bingo_start = select_params[:bingo_start]
      # shift_count = select_params[:shift_count]
      # working_shifts =  select_params[:working_shifts]
      #
      # counts = Hash.new 0
      # working_shifts.map(&:short_name).each {|s| counts[s] += 1 }
      # a1_count = counts['A1']
      # oc_count = counts['OC']
      # tl_count = counts['TL']
      #
      # if test_user.team_leader?
      #   return false if (tl_count < 7) && (self.short_name != 'TL')
      #   return false if (oc_count < 10) && (tl_count >= 7) && (self.short_name != 'OC')
      #
      #   # if prior to end of bingo...
      #   if round <= 4
      #      return false if (all_shifts.count >= 19) || (self.short_name == 'A1')
      #   else
      #     # after bingo
      #     return true
      #   end
      # elsif test_user.group_1? || test_user.group_2? || test_user.group_3?
      #   if round <= 4
      #     return false if ((round <= 4) and (a1_count < 5) and (self.short_name != 'A1'))
      #
      #     if round == 1
      #       return false if ((self.short_name != 'A1') || (working_shifts.count >= 5)) && (a1_count >= 5)
      #       return true
      #     elsif round == 2
      #       return false if (self.short_name != 'A1') && (a1_count < 5)
      #       return false if (self.short_name == 'OC') && ((oc_count >= 5) || (test_user.shifts.count >= 12))
      #       return false if (self.short_name == 'A1') && (a1_count >= 5)
      #       return true
      #     elsif round == 3 || round == 4
      #       return false if (a1_count >= 5) && (oc_count >= 12)
      #       return false if (a1_count >= 5) && (self.short_name == 'A1')
      #       return false if (a1_count < 5) && (self.short_name != 'A1')
      #
      #       max_shifts = (round * 5) + 2 > 19 ? 19 : (round * 5) + 2
      #       return false if test_user.shifts.count >= max_shifts
      #       return true
      #     else
      #       return true
      #     end
      #   else
      #     return false if a1_count < 5 && (self.short_name != 'A1')
      #
      #     return true
      #   end
      # else
      #   return false
      # end
      #
      # retval = true
    end
    retval
  end


  # puts "round: #{round} sn: #{self.short_name} shifts: #{shift_count} wshifts: #{working_shifts.map(&:short_name)} bingo: #{bingo_start}  today: #{Date.today}  sdate: #{self.shift_date}"
  # puts "TEST: #{(self.short_name != 'A1') || (working_shifts.count >= 5)}"

  # puts "s: #{self.short_name}  a1: #{a1_count}   oc: #{oc_count}  #{(self.short_name != 'A1') && (a1_count < 6)}   #{(self.short_name == 'OC') && (working_shifts.count >= 10)}"

  # def can_select_2019(test_user, select_params)
  #   retval = false
  #   return false if (self.shift_date < Date.today) && !test_user.has_role?(:admin)
  #   return false if disabled?
  #   if self.user_id.nil?
  #     return true if test_user.has_role? :admin
  #
  #     all_shifts =  select_params[:all_shifts] #test_user.shifts.to_a
  #     working_shifts =  select_params[:working_shifts] #test_user.shifts.to_a.delete_if {|s| s.meeting? }
  #
  #     return false if test_user.is_working?(self.shift_date)
  #     return true if test_user.admin?
  #     return false if self.team_leader? && !test_user.team_leader?
  #     return false if self.trainer? && !test_user.trainer?
  #     return false if self.training? && !test_user.rookie?
  #
  #     bingo_start = select_params[:bingo_start] #HostConfig.bingo_start_date
  #     round = select_params[:round] #HostUtility.get_current_round(bingo_start, Date.today, test_user)
  #     shift_count = select_params[:shift_count] #working_shifts.count
  #
  #     if self.survey?
  #       return false if !test_user.surveyor?
  #       return false if (round < 5) && (test_user.survey_shift_count >= MAX_SURVEY_COUNT)
  #       return true if self.survey?
  #     end
  #
  #     return false if (round <= 4) && (all_shifts.count >= 20)
  #     return true if test_user.team_leader?
  #     return false if (round <= 0) && (!test_user.rookie? && !test_user.trainer? && !test_user.surveyor?)
  #
  #     if test_user.rookie?
  #       return false if test_user.check_training_shifts(self) == false
  #       if self.is_tour?
  #         return false if (self.shift_date < rookie_tour_date(bingo_start))
  #       end
  #
  #       if round <= 0
  #         return false if shift_count >= 4
  #       elsif round < 5
  #         return false if ((shift_count) >= (round * 5) + 4)
  #       end
  #     else
  #       if round < 5
  #         if test_user.trainer?
  #           return true if self.trainer?
  #           working_list_count = working_shifts.delete_if {|s| s.trainer? }.count
  #           return false if (working_list_count >= (round * 5))
  #         elsif test_user.surveyor?
  #             working_list_count = working_shifts.delete_if {|s| s.survey? }.count
  #             return false if (working_list_count >= (round * 5))
  #         else
  #           return false if (shift_count >= (round * 5))
  #         end
  #       end
  #     end
  #     retval = true
  #   end
  #   retval
  # end

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

  def self.get_shifts_for_index(current_user, return_params, form_filters)
    apply_filters_for_shift_request(form_filters, return_params)

    populate_selectable_flag_for_shifts(current_user, return_params)

    if return_params['show_only_shifts_i_can_pick'] == true
      if return_params['selectable_shifts'].count == 0
        @shifts = @shifts.includes(:shift_type).where('id = 0')
      else
        @shifts = @shifts.includes(:shift_type).where("id in (#{return_params['selectable_shifts'].keys.join(',')})")
      end
      # @shifts = @shifts.includes(:shift_type).order(:shift_date, :short_name, :updated_at desc)
      # @shifts = @shifts.includes(:shift_type).order(:shift_date, :short_name, updated_at: :desc)
    else
      # @shifts = @shifts.includes(:user).includes(:shift_type).order(:shift_date, :short_name)
      # @shifts = @shifts.includes(:shift_type).order(:shift_date, :short_name, updated_at: :desc)
    end
    @shifts.includes(:shift_type).order(:shift_date, :short_name, updated_at: :asc)
  end

  def self.populate_selectable_flag_for_shifts(current_user, return_params)
    all_shifts = current_user.shifts.to_a
    working_shifts = current_user.shifts.to_a.delete_if {|s| s.meeting? || s.trainer? || s.survey?}
    bingo_start = HostConfig.bingo_start_date
    round = HostUtility.get_current_round(bingo_start, Date.today, current_user)
    shift_count = working_shifts.count
    select_params = {all_shifts: all_shifts, working_shifts: working_shifts, bingo_start: bingo_start,
                     round: round, shift_count: shift_count}

    return_params['selectable_shifts'] = {}
    @shifts.each do |shift|
      return_params['selectable_shifts'][shift.id] = "1" if shift.can_select(current_user, select_params)
    end
  end

  def self.apply_filters_for_shift_request(form_filters, return_params)
    return_params['start_from_today'] = (form_filters['start_from_today'] == '1')
    return_params['show_shifts_expanded'] = (form_filters['show_expanded'] == '1')
    return_params['show_only_unselected'] = (form_filters['show_unselected'] == '1')
    return_params['show_only_holidays'] = (form_filters['holiday_shifts'] == '1')
    return_params['include_meeting_shifts'] = (form_filters['show_meetings'] == '1')
    return_params['show_only_shifts_i_can_pick'] = (form_filters['shifts_i_can_pick'] == '1')
    return_params['shift_types_to_show'] = form_filters['shifttype'].reject {|e| e.empty?} unless form_filters['shifttype'] == ''
    return_params['days_of_week_to_show'] = form_filters['dayofweek'].reject {|e| e.empty?}
    return_params['hosts_to_show'] = form_filters['hosts'].reject {|e| e.empty?} if form_filters['hosts']
    return_params['date_set_to_show'] = form_filters['date']
    return_params['date_for_calendar'] = form_filters['date'].empty? ? Date.today.strftime("%Y-%m-%d") : form_filters['date']


    # @shifts = Shift.includes(:shift_type).from_today(return_params['start_from_today']).with_meetings(return_params['include_meeting_shifts'])
    # @shifts = @shifts.includes(:shift_type).by_holidays(return_params['show_only_holidays'])
    # @shifts = @shifts.includes(:shift_type).by_shift_type(return_params['shift_types_to_show']).by_date(return_params['date_set_to_show'])
    # @shifts = @shifts.includes(:shift_type).by_day_of_week(return_params['days_of_week_to_show']).by_users(return_params['hosts_to_show'])
    # @shifts = @shifts.includes(:shift_type).by_unselected(return_params['show_only_unselected'])

    @shifts = Shift.from_today(return_params['start_from_today']).with_meetings(return_params['include_meeting_shifts'])
    @shifts = @shifts.by_holidays(return_params['show_only_holidays'])
    @shifts = @shifts.by_shift_type(return_params['shift_types_to_show']).by_date(return_params['date_set_to_show'])
    @shifts = @shifts.by_day_of_week(return_params['days_of_week_to_show']).by_users(return_params['hosts_to_show'])
    @shifts = @shifts.by_unselected(return_params['show_only_unselected'])

  end

  def self.shifts_for_date(shift_date)
    Shift.where("shift_date = '#{shift_date}'").includes(:user).order('users.name')
  end

  # def can_select_2016(test_user)
  #   retval = false
  #   if self.user_id.nil?
  #     all_shifts =  test_user.shifts.to_a
  #     working_shifts =  test_user.shifts.to_a.delete_if {|s| s.meeting? }
  #
  #     return false if test_user.is_working?(self.shift_date, working_shifts)
  #     return true if test_user.admin?
  #     return false if self.shadow? && !test_user.rookie?
  #     return false if self.team_leader? && !test_user.team_leader?
  #     return false if self.trainer? && !test_user.trainer?
  #
  #     bingo_start = HostConfig.bingo_start_date
  #     round = HostUtility.get_current_round(bingo_start, Date.today, test_user)
  #     shift_count = working_shifts.count
  #
  #     return false if (round <= 4) && (all_shifts.count >= 20)
  #     return true if test_user.team_leader?
  #     return false if (round <= 0) && (!test_user.rookie? && !test_user.trainer?)
  #
  #     if test_user.rookie?
  #       last_shadow = test_user.last_shadow(working_shifts)
  #       return false if !self.shadow? && (last_shadow.nil? || (self.shift_date < last_shadow))
  #
  #       shadow_count = test_user.shadow_count(working_shifts)
  #       if (shadow_count < SHADOW_COUNT)
  #         return false if !self.shadow?
  #         return true
  #       else
  #         return false if self.shadow?
  #         return false if (round < 3) && !self.rookie_training_type?
  #         return false if (round <= 0) && (all_shifts.count >= 9)
  #
  #         if round < 5
  #           return false if ((shift_count) >= (round * 5)) && (round > 0)
  #           return false if (round == 4) && (all_shifts.count >= 20)
  #         end
  #
  #         unless self.rookie_training_type?
  #           return false if test_user.not_done_training(self.shift_date, working_shifts)
  #         end
  #       end
  #     else
  #       if round < 5
  #         if test_user.trainer?
  #           return false if all_shifts.count >= 20
  #           return true if self.trainer?
  #           non_trainer_shift_count = working_shifts.delete_if {|s| s.trainer? }.count
  #           return false if (non_trainer_shift_count >= (round * 5))
  #         else
  #           return false if (shift_count >= (round * 5))
  #         end
  #       end
  #     end
  #     retval = true
  #
  #   end
  #   retval
  # end

  private
  def set_day_of_week
    self.day_of_week = self.shift_date.strftime("%a")
  end

  def set_short_name
    self.short_name = self.shift_type.short_name[0..1].upcase
  end

  def rookie_tour_date(season_start_date)
    ROOKIE_TOUR_DATE
  end


end
