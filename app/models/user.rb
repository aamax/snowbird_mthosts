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
#

class User < ActiveRecord::Base
  include HostConfig
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :registerable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :street, :city, :state, :zip,
                  :home_phone, :cell_phone, :alt_email, :start_year, :notes, :confirmed, :active_user, :nickname,
                  :working_shifts
  attr_accessor   :working_shifts

  has_many :shifts

  scope :active_users, -> {where(active_user: true)}
  scope :inactive_users, -> {where(active_user: false)}
  scope :non_confirmed_users, -> {where(confirmed: false)}

  scope :rookies, -> {where("start_year = #{HostConfig.season_year} and active_user = true")}
  scope :group1, -> {where("(start_year < ?) and (start_year >= ?) and (active_user = true)", HostConfig.season_year, HostConfig.group_1_year)}
  scope :group2, -> {where("(start_year <= ?) and (start_year > ?) and (active_user = true)", HostConfig.group_2_year, HostConfig.group_3_year)}
  scope :group3, -> {where("(start_year <= ?) and (active_user = true)", HostConfig.group_3_year)}

  before_destroy :clear_shifts_on_destroy

  # don't allow non active users to log into the system
  def active_for_authentication?
    super and self.active_user?
  end

  def seniority
    if self.active_user != true
      retval = 'InActive'
    else
      retval = "Rookie" if self.start_year == HostConfig.season_year
      retval = "Freshman" if (self.start_year < HostConfig.season_year) && (self.start_year >= HostConfig.group_1_year)
      retval = "Junior" if (self.start_year <= HostConfig.group_2_year) && (self.start_year > HostConfig.group_3_year)
      retval = "Senior" if self.start_year <= HostConfig.group_3_year
    end
    retval
  end

  def shifts_worked
    worked = shifts
    worked.delete_if {|s| (s.shift_date > Date.today) || (s.shift_status_id == -1) }
    worked
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
    self.start_year < HostConfig.group_2_year
  end

  def group_2?
    (self.start_year >= HostConfig.group_2_year) && (self.start_year < HostConfig.group_1_year)
  end

  def group_1?
    (self.start_year >= HostConfig.group_1_year) && (self.start_year != HostConfig.season_year)
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
    elsif self.group_1? || self.rookie?
      retval = 4
    end
    retval
  end

  def shift_status_message
    msg = []
    day_offset = get_day_offset
    num_selected = self.shifts.length
    round = HostUtility.get_current_round(HostConfig.bingo_start_date, Date.today, self)
    if has_holiday_shift?
      msg << "A Holiday Shift has been selected."
    else
      msg << "NOTE:  A Holiday Shift needs to be selected"
    end

    if self.rookie?
      if shadow_count < 2
        msg << "#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts."
      elsif shadow_count == 2
        msg << "All Shadow Shifts Selected."
        msg << "Cannot Pick Shifts Prior to Last Shadow: #{self.last_shadow.strftime("%Y-%m-%d")}"
      end
      if self.round_one_type_count == 5
        msg << "All Round One Rookie Shifts Selected."
        msg << "Cannot Pick Non-Round One Rookie Type Shifts Prior to #{self.round_one_end_date.strftime("%Y-%m-%d")}"
        if ((round == 2) && self.shifts.length == 12) || (self.shifts.length >= 16)
          msg << "All Round #{round} Shifts Selected."
        else
          if round == 2
            msg << "#{self.shifts.length} of 12 selected.  Need #{12 - self.shifts.length} Round 2 Shifts."
          else
            msg << "#{self.shifts.length} of 16 selected.  Need #{16 - self.shifts.length} Round #{round} Shifts."
          end
        end


        #case round
        #  when 0..1
        #  when 2
        #  when 3
        #  when 4
        #
        #  else
        #
        #end

      else
        if (self.round_one_type_count < 5) && (self.shifts.length >= 2)
          msg << "#{self.round_one_type_count} of 5 Round One Rookie Shifts Selected.  Need #{5 - self.round_one_type_count} Round One Rookie Shifts."
        end
      end
    else
      case round
        when 0
          msg << "No Shifts may be selected before the selection rounds start."
          msg << "you may start selecting shifts on #{HostConfig.bingo_start_date + day_offset.days}"
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
            msg << "All required shifts selected. (#{num_selected} of 18)"
          end
      end
    end
    msg
  end

  private

  def clear_shifts_on_destroy
    self.shifts.each do |s|
      s.user_id = nil
      s.save
    end
  end
end
