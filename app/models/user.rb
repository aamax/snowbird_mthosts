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
#  head_shot              :string(255)
#


# noinspection RubyInterpreter
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
  has_many :shift_logs

  has_many :riders
  has_many :host_haulers, through: :riders

  has_many :ongoing_trainings
  has_many :training_dates, through: :ongoing_trainings

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
    super and self.has_role?(:admin) ? true : (self.active_user? || (self.email == 'kmcguinness@snowbird.com'))
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
    # tourshifts = []
    # ShiftType.all.each do |st|
    #   tourshifts << st.id if st.is_tour? 
    # end
    retval = []
    self.non_meeting_shifts.each do |s|
      retval << s if s.is_tour?
    end
    retval
  end

  def surveys
    self.shifts.where(short_name: "SV")
  end

  def trainers
    self.shifts.where(short_name: "TR")
  end

  def trainings
    self.shifts.where("short_name in ('T1','T2','T3', 'T4')")
  end

  def ongoing_training_display
    retval = ''
    return 'rookie' if self.rookie?

    if self.ongoing_trainings.count > 1
      retval = self.ongoing_trainings.count
    elsif self.ongoing_trainings.count == 1
      if self.ongoing_trainings.first.shift_date.strftime("%Y-%m-%d") == OGOMT_FAKE_DATE
        retval = 'LY Credit'
      else
        retval = 'TY'
      end
    end
    retval
  end

  def team_leaders
    self.shifts.where("shift_type_id in (#{ShiftType.team_lead_type.map(&:id).join(",")})")
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

  def ongoing_trainer?
    self.has_role? :ongoing_trainer
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
    worked = shifts_for_credit
    worked = worked.to_a.delete_if { |s|
      (s.shift_date > Date.today) || (s.shift_status_id == -1)
    }
    worked
  end

  def pending_shifts
    pending = shifts_for_credit
    pending = pending.to_a.delete_if {|s| (s.shift_date <= Date.today) }
    pending
  end

  def missed_shifts
    missed = shifts_for_credit
    missed = missed.to_a.delete_if {|s| (s.shift_status_id != -1) }
    missed
  end

  def team_leader?
    self.has_role? :team_leader
  end

  def surveyor?
    self.has_role? :surveyor
  end

  def admin?
    self.has_role? :admin
  end

  def driver?
    self.has_role? :driver
  end

  def rookie?
    self.start_year == HostConfig.season_year
  end

  def group_3? # freshman
   # self.start_year <= HostConfig.group_3_year
    (self.start_year < HostConfig.season_year) && (self.start_year >= HostConfig.group_3_year)
  end

  def group_2? # juniors
    #(self.start_year <= HostConfig.group_2_year) && (self.start_year > HostConfig.group_3_year)
    (self.start_year <= HostConfig.group_2_year) && (self.start_year > HostConfig.group_1_year)
  end

  def group_1? #seniors
    #(self.start_year < HostConfig.season_year) && (self.start_year >= HostConfig.group_1_year)
    self.start_year <= HostConfig.group_1_year
  end

  def is_working?(shift_date, working_shifts=nil)
    return true if is_ongoing_training?(shift_date)
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

  def is_ongoing_training?(shift_date)
    self.training_dates.map(&:shift_date).include? shift_date
  end

  def has_ongoing_training_shift?
    if rookie?
      true
    else
      ongoing_trainings.count > 0
    end
  end

  def self.get_host_emails_for_date(dt)
    users = Shift.where(shift_date: dt).map {|s| s.user }.reject { |e| e.to_s.empty? }
    training_shifts = TrainingDate.where(shift_date: dt)&.first&.ongoing_trainings&.where("user_id is not null")
    users.concat training_shifts.map(&:user) if training_shifts

    emailaddress = users.map(&:email).join(',')
  end

  def can_select_ongoing_training(shift_date)
    return true if admin?
    return false if  is_working?(shift_date)
    return false if (round1_date > Date.today)
    return false if rookie?

    if !ongoing_trainer?
      return false if (ongoing_trainings.count > 0)
      qry_str = 'user_id is null and is_trainer = false'
      return TrainingDate.where(shift_date: shift_date).first.ongoing_trainings.where(qry_str).count > 0
    end

    return true
  end

  def get_shift_list
    self.shifts.includes(:shift_type).sort {|a,b| a.shift_date <=> b.shift_date }
  end

  def get_working_shifts
    user = User.includes(:shifts).find_by_id(id)
    shifts = user.shifts.includes(:shift_type).to_a
    shifts ||= []
    shifts.concat user.ongoing_trainings

    working_shifts = shifts.flatten.sort {|a,b| a.shift_date <=> b.shift_date }
  end

  def shifts_for_credit
    user = User.includes(:shifts).find_by_id(id)
    shifts = user.shifts.includes(:shift_type).to_a
    shifts ||= []
    # trainings_for_count = user.ongoing_trainings.to_a.delete_if { |s| !s.is_trainer? }
    # shifts.concat trainings_for_count
    shifts.flatten.sort {|a,b| a.shift_date <=> b.shift_date }
  end

  def shifts_for_analysis
    user = User.includes(:shifts).find_by_id(id)
    shifts = user.shifts.includes(:shift_type).to_a
    shifts ||= []
    shifts.flatten.sort {|a,b| a.shift_date <=> b.shift_date }
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

  def has_ongoign_training_shift?
    (self.ongoing_trainings.count > 0) && !rookie?
  end

  def get_day_offset
    retval = 0
    if self.group_3? || self.group_2?
      retval = 1
    elsif self.rookie?
      retval = 2
    end
    retval
  end

  def survey_shift_count
    self.shifts.where(short_name: 'SV').count
  end

  def trainer_shift_count
    self.shifts.where(short_name: 'TR').count
  end

  def team_leader_shift_count
    team_leaders.count
  end

  def training_shifts_list
    training_shifts = []
    shifts.order(:shift_date).each do |s|
      training_shifts << s if s.training?
    end
    training_shifts
  end

  def check_training_shifts(shift)
    training_shifts = training_shifts_list
    if training_shifts.count < 4
      return false unless shift.training?
      return false if training_shifts.map(&:short_name).include? shift.short_name
      if shift.short_name == 'T1'
        return true if training_shifts.count == 0
        return false if shift.shift_date >= training_shifts[0].shift_date
      else
        t1 = training_shifts.delete_if {|s| s.short_name != 'T1'}.first
        return false if t1.nil? || (t1.shift_date > shift.shift_date)
      end
    else
      return false if shift.training? || (shift.shift_date < training_shifts.last.shift_date)
    end
    true
  end

  def shift_status_message
    msg = []
    day_offset = get_day_offset
    num_selected = self.get_working_shifts.length
    round = HostUtility.get_current_round(HostConfig.bingo_start_date, Date.today, self)
    all_shifts = self.shifts

    if round < 5
      msg << "You are currently in <strong>round #{round}</strong>."
    else
      msg << "You are done with Shift Selection Bingo!"
    end

    msg << "Today is: #{Date.today}"
    msg << "Bingo Start: #{HostConfig.bingo_start_date}"

    host_selection_message(all_shifts, round, day_offset, msg)

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

  def self.sort_value(user)
    user.nil? ? '' : user.name
  end

  def self.populate_meetings
    puts "Populating Meetings"
    meetings = ShiftType.where("short_name like 'M%'")
    Shift.delete_all("shift_type_id in (#{meetings.map(&:id).join(',')})")
    Rake::Task['db:load_meetings'].invoke

    #
    # first_date = SysConfig.first.season_start_date
    # shift_types = {}
    # ShiftType.all.each {|st| shift_types[st.short_name] = st.id }
    #
    # User.all.each do |u|
    #   next if u.supervisor? || (u.active_user == false)
    #
    #   MEETINGS.each do |m|
    #     next if ((m[:type] == "M1") || (m[:type] == "M3")) && !u.rookie?
    #
    #     s_date = Date.parse(m[:when])
    #     st = shift_types[m[:type]]
    #
    #     new_shift = Shift.create(:user_id=>u.id,
    #                              :shift_type_id=>st,
    #                              :shift_date=>s_date,
    #                              :shift_status_id => 1,
    #                              :day_of_week=>s_date.strftime("%a"))
    #   end
    # end
  end

  def self.reset_all_accounts
    User.all.each do |u|
      if !u.active_user?
        u.remove_role :admin
        u.remove_role :team_leader
        u.remove_role :trainer
        u.remove_role :surveyor
        u.remove_role :driver
        u.remove_role :ongoing_trainer
      end
      u.confirmed = false
      u.password = DEFAULT_PASSWORD
      u.save
    end
  end

  private

  def clear_shifts_on_destroy
    self.shifts.each do |s|
      s.user_id = nil
      s.save
    end
  end


  def rookie_training_message(all_shifts, round, msg)
    tshifts = all_shifts.where("short_name in ('T1', 'T2', 'T3', 'T4')").map(&:short_name).uniq

    if tshifts.length == 4
      msg << "You have selected all your training shifts"
      return
    end

    if tshifts.count == 0
      msg << "You have not selected any training shifts"
      return
    end

    msg << "You need to select a T1 shift" unless tshifts.include? 'T1'
    msg << "You need to select a T2 shift" unless tshifts.include? 'T2'
    msg << "You need to select a T3 shift" unless tshifts.include? 'T3'
    msg << "You need to select a T4 shift" unless tshifts.include? 'T4'
  end

  def rookie_selection_message(all_shifts, round, msg)
    case round
      when 0
        msg << "You have #{all_shifts.count} of 8 shifts selected"
      when 1..2
        limit = 8 + (round * 5)
        msg << "You have #{all_shifts.count} of #{limit} shifts selected"
      when 3..4
        if all_shifts.count < 20
          msg << "You have #{all_shifts.count} of 20 shifts selected"
        else
          msg << "You have 20 shifts selected"
        end
      else
        if all_shifts.count < 20
          msg << "#{all_shifts.count} of 20 Shifts Selected.  You need to pick #{20 - all_shifts.count}"
        else
          msg << "You have at least 20 shifts selected"
        end
    end
  end

  def host_selection_message(all_shifts, round, day_offset, msg)
    if self.team_leader?
      counts = Hash.new 0
      all_shifts.map(&:short_name).each {|s| counts[s] += 1 }
      a1_count = counts['A1']
      oc_count = counts['OC']
      tl_count = counts['TL']

      msg << "#{tl_count} team leader shifts selected"
      msg << "#{oc_count} On Call shifts selected"
      msg << "#{a1_count} A1 Shifts Selected"

      if (a1_count >= 7) && (oc_count >= 10) && (all_shifts.count >= 19)
        msg << "All Required Shifts Selected"
      else
        if a1_count < 7
          msg << "You still need #{7 - tl_count} TL Shifts"
        end
        if oc_count < 10
          msg << "You still need #{10 - oc_count} OC Shifts"
        end
      end
    end

    if !self.team_leader?
      case round
        when 0
          msg << "No Selections Until #{HostConfig.bingo_start_date + day_offset.days}."
        when 1..3
          limit = round * 5 + 2
          limit = 19 if limit > 19

          if all_shifts.count < limit
            msg << "#{all_shifts.count} of #{limit} Shifts Selected.  You need to pick #{limit - all_shifts.count}"
          else
            msg << "All required shifts selected for round #{round}. (#{all_shifts.count} of #{limit})"
          end
        else
          if all_shifts.count < 19
            msg << "#{all_shifts.count} of #{19} Shifts Selected.  You need to pick #{19 - all_shifts.count}"
          else
            msg << "You have at least #{19} shifts selected"
          end
      end
    end
  end


end
