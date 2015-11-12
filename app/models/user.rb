
class User < ActiveRecord::Base
  include HostConfig
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, registerable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :street, :city, :state, :zip,
                  :home_phone, :cell_phone, :alt_email, :start_year, :notes, :confirmed, :active_user, :nickname,
                  :working_shifts, :snowbird_start_year, :head_shot
  attr_accessor   :working_shifts

  has_many :shifts, -> { order "shift_date ASC" }
  has_many :galleries
  has_many :surveys

  scope :active_users, -> {where(active_user: true)}
  scope :inactive_users, -> {where(active_user: false)}
  scope :non_confirmed_users, -> {where(confirmed: false)}

  scope :rookies, -> {where("start_year = #{HostConfig.season_year} and active_user = true")}
  scope :group3, -> {where("(start_year < ?) and (start_year >= ?) and (active_user = true)", HostConfig.season_year, HostConfig.group_3_year)}
  scope :group2, -> {where("(start_year <= ?) and (start_year > ?) and (active_user = true)", HostConfig.group_2_year, HostConfig.group_1_year)}
  scope :group1, -> {where("(start_year <= ?) and (active_user = true)", HostConfig.group_1_year)}

  before_destroy :clear_shifts_on_destroy

  def self.team_leader_count
    User.all.to_a.delete_if {|u| !u.team_leader?}.length
  end

  # don't allow non active users to log into the system
  def active_for_authentication?
    super and self.has_role?(:admin) ? true : (self.active_user? || (self.email == 'jcollins@snowbird.com'))
  end

  def non_meeting_shifts
    arr = ShiftType.where("short_name like 'M%'").map {|st| st.id}
    retval = []
    self.shifts.each do |s|
      retval << s if !arr.include?(s.shift_type_id)
    end
    retval #= self.shifts.delete_if {|s| arr.include? s.shift_type_id }
  end

  def inactive_message
    "Sorry, this account has been deactivated."
  end

  def tour_ratio
    ratio = 0.0
    total = self.non_meeting_shifts.size

    ratio = tours.length.to_f / total if total != 0
    ratio * 100
  end

  def tours
    tourshifts = []
    ShiftType.all.each do |st|
      tourshifts << st.id if (!st.tasks.nil? && st.tasks.downcase.include?('tour'))
    end
    retval = []
    self.non_meeting_shifts.each do |s|
      retval << s if tourshifts.include? s.shift_type_id
    end
    retval
  end

  def address
    "#{self.street}, #{self.city}, #{self.state} #{self.zip}"
  end

  def seniority
    if (self.active_user != true) && (self.name != 'John Cotter')
      retval = 'InActive'
    elsif self.name == 'John Cotter'
      retval = 'Supervisor'
    else
      retval = "Rookie" if self.rookie?
      retval = "Group 1 (Senior)" if self.group_1?
      retval = "Group 2 (Middle)" if self.group_2?
      retval = "Group 3 (Newer)" if self.group_3?
    end
    retval
  end

  def seniority_group
    if self.active_user != true
      retval = 5
    else
      retval = 1 if self.group_1?
      retval = 2 if self.group_2?
      retval = 3 if self.group_3?
      retval = 4 if self.rookie?
    end
    retval
  end

  def supervisor?
    self.email == 'jecotterii@gmail.com'
  end

  def trainer?
    self.has_role? :trainer
  end

  def is_max?
    self.email.downcase == MAX_EMAIL
  end

  def shifts_worked
    worked = shifts
    worked = worked.to_a.delete_if {|s| (s.shift_date > Date.today) || (s.shift_status_id == -1) }
    worked
  end

  def pending_shifts
    pending = shifts
    pending = pending.to_a.delete_if {|s| (s.shift_date <= Date.today) }
    pending
  end

  def missed_shifts
    missed = shifts
    missed = missed.to_a.delete_if {|s| (s.shift_status_id != -1) }
    missed
  end


  def team_leader?
    self.has_role? :team_leader
  end

  def admin?
    self.has_role? :admin
  end

  def rookie?
    self.start_year == HostConfig.season_year
  end

  def group_3?
   # self.start_year <= HostConfig.group_3_year
    (self.start_year < HostConfig.season_year) && (self.start_year >= HostConfig.group_3_year)

  end

  def group_2?
    #(self.start_year <= HostConfig.group_2_year) && (self.start_year > HostConfig.group_3_year)
    (self.start_year <= HostConfig.group_2_year) && (self.start_year > HostConfig.group_1_year)
  end

  def group_1?
    #(self.start_year < HostConfig.season_year) && (self.start_year >= HostConfig.group_1_year)
    self.start_year <= HostConfig.group_1_year
  end

  def group_1_only?
    self.start_year <= HostConfig.group_1_year && !self.team_leader?
  end

  def shadow_count(working_shifts=nil)
    iCnt = 0
    if working_shifts.nil?
      working_shifts = self.shifts
    end
    working_shifts.each do |s|
      iCnt += 1 if s.shadow?
    end
    iCnt
  end

  def training_shift_count(working_shifts=nil)
    iCnt = 0
    if working_shifts.nil?
      working_shifts = self.shifts
    end
    working_shifts.each do |s|
      iCnt += 1 if s.rookie_training_type?
      break if iCnt >= 6
    end
    iCnt
  end

  def last_training_date(working_shifts=nil)
    iCnt = 0
    dt = nil
    if working_shifts.nil?
      working_shifts = self.shifts
    end
    working_shifts.each do |s|
      if s.rookie_training_type?
        iCnt += 1
        dt = s.shift_date
      end

      break if iCnt >= 6
    end
    dt
  end

  def not_done_training(shift_date, working_shifts)
    iCnt = 0
    dt = nil
    working_shifts.each do |s|
      if s.rookie_training_type?
        iCnt += 1
        dt = s.shift_date
      end
      next if dt.nil?
      return true if  (dt > shift_date)
    end
    return (iCnt < 6) || dt.nil?
  end

  def first_non_shadow
    dt = nil
    self.shifts.each do |s|
      if !s.shadow?
        dt = s.shift_date
        break
      end
    end
    dt
  end

  def last_shadow(working_shifts=nil)
    dt = nil
    iCnt = 0
    if working_shifts.nil?
      working_shifts = self.shifts
    end
    working_shifts.each do |s|
      if s.shadow?
        dt = s.shift_date if dt.nil? || (dt < s.shift_date)
        iCnt += 1
      end
      break if iCnt >= SHADOW_COUNT
    end
    dt
  end

  def is_working?(shift_date, working_shifts=nil)
    if working_shifts.nil?
      working_shifts = self.shifts
    end
    working_shifts.each do |s|
      next if s.meeting?
      if s.shift_date == shift_date
        return true
      end
    end
    false
  end

  def get_shift_list
    self.shifts.includes(:shift_type).sort {|a,b| a.shift_date <=> b.shift_date }
  end

  def get_working_shifts
    user = User.includes(:shifts).find_by_id(id)
    shifts = user.shifts.includes(:shift_type)
    shifts ||= []
    working_shifts = shifts.flatten.sort {|a,b| a.shift_date <=> b.shift_date }
  end

  def get_next_shifts(num)
    working_shifts = get_working_shifts
    working_shifts.to_a.delete_if {|s| s.shift_date < Date.today }
    limit = num - 1
    working_shifts[0..limit]
  end

  def has_holiday_shift?
    need_holiday = true
    self.shifts.each do |s|
      if ((HOLIDAYS.include? s.shift_date))
        need_holiday = false
        break
      end
    end
    !need_holiday
  end

  def get_day_offset
    retval = 0
    if self.group_2?
      retval = 1
    elsif self.group_3? || self.rookie?
      retval = 2
    end
    retval
  end

  def shift_status_message
    msg = []
    day_offset = get_day_offset
    num_selected = self.shifts.length
    round = HostUtility.get_current_round(HostConfig.bingo_start_date, Date.today, self)
    has_holiday = has_holiday_shift?
    all_shifts = self.shifts

    msg << "You are currently in <strong>round #{round}</strong>." if round < 5
    msg << "You have #{num_selected} shifts selected."
    if has_holiday == true
      msg << "A <strong>Holiday Shift</strong> has been selected." #if round < 5
    else
      msg << "NOTE:  You still need a <strong>Holiday Shift</strong>"
    end

    if self.rookie?
      if shadow_count < SHADOW_COUNT
        msg << "#{shadow_count} of #{SHADOW_COUNT} selected.  Need #{SHADOW_COUNT - shadow_count} Shadow Shifts."

        if all_shifts.count > 0
          msg << "Shifts Only Before: #{self.first_non_shadow.strftime("%Y-%m-%d")}" unless self.first_non_shadow.nil?
        end
      else
        msg << "All Shadow Shifts Selected."

        case round
          when 0..4
            limit = round * 5 + 4
            limit = 20 if limit > 20
            limit = 9 if limit == 4
            if all_shifts.count < limit
              msg << "#{all_shifts.count} of #{limit} Shifts Selected.  You need to pick #{limit - all_shifts.count}"
            else
              msg << "All required shifts selected for round #{round}. (#{all_shifts.count} of #{limit})"
            end
          else
            if all_shifts.count < 20
              msg << "#{all_shifts.count} of 20 Shifts Selected.  You need to pick #{20 - all_shifts.count}"
            else
              msg << "All required shifts selected." if has_holiday
            end
        end
      end
    else
      case round
        when 0
          msg << "No Selections Until #{HostConfig.bingo_start_date + day_offset.days}."
        when 1..4
          trshifts = 0
          if self.trainer?
            trshifts = self.shifts.to_a.delete_if {|sh| !sh.trainer? }.count
          end
          limit = round * 5 + 2 + trshifts
          limit = 20 if limit > 20

          if all_shifts.count < limit
            msg << "#{all_shifts.count} of #{limit} Shifts Selected.  You need to pick #{limit - all_shifts.count}"
          else
            msg << "All required shifts selected for round #{round}. (#{all_shifts.count} of #{limit})"
          end
        else
          if num_selected < 20
            msg << "#{all_shifts.count} of 20 Shifts Selected.  You need to pick #{20 - all_shifts.count}"
          else
            msg << "All required shifts selected." if has_holiday
          end
      end
    end
    msg
  end

  def round1_date
    HostUtility.date_for_round(self, 1)
  end

  def round2_date
    HostUtility.date_for_round(self, 2)
  end

  def round3_date
    HostUtility.date_for_round(self, 3)
  end

  def round4_date
    HostUtility.date_for_round(self, 4)
  end

  def first_name
    self.name.split(' ')[0]
  end

  def last_name
    self.name.split(' ')[1..self.name.length].join(' ')
  end

  def self.populate_meetings
    meetings = ShiftType.where("short_name = 'M1' OR short_name = 'M2' OR short_name = 'M3' OR short_name = 'M4'").map {|st| st.id}.join(',')

    Shift.delete_all("shift_type_id in (#{meetings})")

    first_date = SysConfig.first.season_start_date
    shift_types = {}
    ShiftType.all.each {|st| shift_types[st.short_name] = st.id }

    User.all.each do |u|
      next if u.supervisor? || (u.active_user == false)

      MEETINGS.each do |m|
        next if ((m[:type] == "M1") || (m[:type] == "M3")) && !u.rookie?

        s_date = Date.parse(m[:when])
        st = shift_types[m[:type]]

        new_shift = Shift.create(:user_id=>u.id,
                                 :shift_type_id=>st,
                                 :shift_date=>s_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>s_date.strftime("%a"))
      end
    end
  end

  private

  def clear_shifts_on_destroy
    self.shifts.each do |s|
      s.user_id = nil
      s.save
    end
  end


end
