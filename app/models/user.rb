# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  street                 :string(255)
#  city                   :string(255)
#  state                  :string(255)
#  zip                    :string(255)
#  home_phone             :string(255)
#  cell_phone             :string(255)
#  alt_email              :string(255)
#  start_year             :integer
#  notes                  :text
#  confirmed              :boolean
#  active_user            :boolean
#  nickname               :string(255)
#  snowbird_start_year    :integer
#

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

  has_many :shifts
  has_many :galleries
  has_many :surveys

  scope :active_users, -> {where(active_user: true)}
  scope :inactive_users, -> {where(active_user: false)}
  scope :non_confirmed_users, -> {where(confirmed: false)}

  scope :rookies, -> {where("start_year = #{HostConfig.season_year} and active_user = true")}
  #scope :group1, -> {where("(start_year < ?) and (start_year >= ?) and (active_user = true)", HostConfig.season_year, HostConfig.group_1_year)}
  #scope :group2, -> {where("(start_year <= ?) and (start_year > ?) and (active_user = true)", HostConfig.group_2_year, HostConfig.group_3_year)}
  #scope :group3, -> {where("(start_year <= ?) and (active_user = true)", HostConfig.group_3_year)}
  scope :group3, -> {where("(start_year < ?) and (start_year >= ?) and (active_user = true)", HostConfig.season_year, HostConfig.group_3_year)}
  scope :group2, -> {where("(start_year <= ?) and (start_year > ?) and (active_user = true)", HostConfig.group_2_year, HostConfig.group_1_year)}
  scope :group1, -> {where("(start_year <= ?) and (active_user = true)", HostConfig.group_1_year)}

  before_destroy :clear_shifts_on_destroy

  # don't allow non active users to log into the system
  def active_for_authentication?
    super and self.has_role?(:admin) ? true : self.active_user?
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

  def shifts_worked
    worked = shifts.delete_if {|s| (s.shift_date > Date.today) || (s.shift_status_id == -1) }
    worked
  end

  def pending_shifts
    pending = shifts.delete_if {|s| (s.shift_date <= Date.today) }
  end

  def missed_shifts
    pending = shifts.delete_if {|s| (s.shift_status_id == -1) }
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

  def shadow_count
    iCnt = 0
    self.shifts.each do |s|
      iCnt += 1 if s.shadow?
      break if iCnt >= 2
    end
    iCnt
  end

  def round_one_type_count
    iCnt = 0
    self.shifts.each do |s|
      if s.round_one_rookie_shift?
        iCnt += 1
        break if iCnt >= 5
      else
        break if !s.shadow?
      end
    end
    iCnt
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


  def round_one_end_date
    dt = nil
    iCnt = 0
    self.shifts.each do |s|
      if s.round_one_rookie_shift?
        dt = s.shift_date
        iCnt += 1
      end
      break if iCnt >= 5
    end
    dt
  end

  def first_round_one_end_date
    dt = nil
    iCnt = 0
    self.shifts.each do |s|
      if s.round_one_rookie_shift?
        dt = s.shift_date
        break
      end
    end
    dt
  end

  def first_non_round_one_end_date
    dt = nil
    iCnt = 0
    self.shifts.each do |s|
      if !s.round_one_rookie_shift? && !s.shadow?
        dt = s.shift_date
        break
      end
    end
    dt
  end

  def has_non_round_one?
    !first_non_round_one_end_date.nil?
  end

  def last_shadow
    dt = nil
    iCnt = 0
    self.shifts.each do |s|
      if s.shadow?
        dt = s.shift_date
        iCnt += 1
      end
      break if iCnt >= 2
    end
    dt
  end

  def is_working? shift_date
    self.shifts.each do |s|
      if s.shift_date == shift_date
        return true
      end
    end
    false
  end

  def get_meetings
    meetings = []
    first_date = Date.today
    MEETINGS.each do |m|
      unless self.rookie?
        if ((m[:type] == "M1") || (m[:type] == "M3"))
          next
        end
      end

      if m[:when] >= first_date.strftime("%Y-%m-%d")
        s_date = DateTime.parse(m[:when])
        st = ShiftType.find_by_short_name(m[:type])
        next if st.nil?
        new_shift = Shift.new(:user_id=>self.id,
                              :shift_type_id=>st.id,
                              :shift_date=>s_date,
                              :shift_status_id => 1,
                              :day_of_week=>s_date.strftime("%a"))
        meetings << new_shift
      end
    end
    meetings
  end

  def get_working_shifts
    working_shifts = self.shifts + get_meetings
    working_shifts = working_shifts.flatten
  end

  def get_next_shifts(num)
    working_shifts = get_working_shifts
    working_shifts.delete_if {|s| s.shift_date < Date.today }
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
      retval = 2
    elsif self.group_3? || self.rookie?
      retval = 4
    end
    retval
  end

  def shift_status_message
    msg = []
    day_offset = get_day_offset
    num_selected = self.shifts.length
    round = HostUtility.get_current_round(HostConfig.bingo_start_date, Date.today, self)
    has_holiday = has_holiday_shift?

    msg << "You are currently in <strong>round #{round}</strong>." if round < 5

    if has_holiday
      msg << "A <strong>Holiday Shift</strong> has been selected." if round < 5
    else
      msg << "NOTE:  You still need a <strong>Holiday Shift</strong>"
    end

    if self.rookie?
      if shadow_count < 2
        msg << "#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts."

        if self.shifts.count > 0
          msg << "Shifts Only Before: #{self.first_non_shadow.strftime("%Y-%m-%d")}" unless self.first_non_shadow.nil?
        end
      else
        msg << "All Shadow Shifts Selected."

        if self.round_one_type_count < 5
          if self.has_non_round_one?
            msg << "Round 1 Type Shifts Only Between #{self.last_shadow} and #{self.first_non_round_one_end_date.strftime("%Y-%m-%d")}"
          else
            msg << "Round One Type Shifts Only After: #{self.last_shadow.strftime("%Y-%m-%d")}"
          end
          msg << "#{self.round_one_type_count} of 5 selected.  Need #{5 - self.round_one_type_count} Round 1 Rookie Shifts."
        else
          # shadows = 2.  round 1 = 5
          msg << "All Round One Rookie Shifts Selected."
          msg << "Round 1 Type Shifts Only Between #{self.last_shadow.strftime("%Y-%m-%d")} and #{self.round_one_end_date.strftime("%Y-%m-%d")}."
          #if !self.first_non_round_one_end_date.nil?
          #  msg << "Round 1 Type Shifts Only Between #{self.last_shadow.strftime("%Y-%m-%d")} and #{self.first_non_round_one_end_date.strftime("%Y-%m-%d")}."
          #else
          #  msg << "Round 1 Type Shifts Only Between #{self.last_shadow.strftime("%Y-%m-%d")} and #{self.round_one_end_date.strftime("%Y-%m-%d")}."
          #end

          msg << "Any Shifts After #{self.round_one_end_date.strftime("%Y-%m-%d")}"

          round == 2 ? total_for_round = 12 : round <= 1 ? total_for_round = 7 : total_for_round = 16
          msg << "#{self.shifts.count} of #{total_for_round} shifts selected." if (self.shifts.count <= total_for_round)
          msg << "All Required Shifts Selected." if (self.shifts.count >= total_for_round)
        end
      end
    else
      case round
        when 0
          msg << "No Selections Until #{HostConfig.bingo_start_date + day_offset.days}."
        when 1..4
          limit = round * 5
          limit = 18 if (round == 4)
          if self.shifts.length < limit
            msg << "#{num_selected} of #{limit} Shifts Selected.  You need to pick #{limit - num_selected}"
          else
            msg << "All required shifts selected for round #{round}. (#{num_selected} of #{limit})"
          end
        else
          if num_selected < 18
            msg << "#{num_selected} of 18 Shifts Selected.  You need to pick #{18 - num_selected}"
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

  def round1_msg
    if self.rookie?
      'You may select up to 7 shifts: (2) Shadow and (5) G1-G4 type shifts (excluding G3, G4 shifts on the Friday schedule)'
    else
      'You may select up to 5 shifts.'
    end
  end

  def round2_date
    HostUtility.date_for_round(self, 2)
  end

  def round2_msg
    if self.rookie?
      'You may select up to 12 shifts: You may not select non-round one type shifts prior to the 5th one you have already selected'
    else
      'You may select up to 10 shifts.'
    end
  end

  def round3_date
    HostUtility.date_for_round(self, 3)
  end

  def round3_msg
    if self.rookie?
      'You may select up to 16 shifts: You may not select non-round one type shifts prior to the 5th one you have already selected'
    else
      'You may select up to 15 shifts.'
    end
  end

  def round4_date
    HostUtility.date_for_round(self, 4)
  end

  def round4_msg
    if self.rookie?
      'You may select up to 16 shifts: You may not select non-round one type shifts prior to the 5th one you have already selected'
    else
      'You may select up to 18 shifts.'
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
