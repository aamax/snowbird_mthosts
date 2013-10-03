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
  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :registerable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :street, :city, :state, :zip,
                  :home_phone, :cell_phone, :alt_email, :start_year, :notes, :confirmed, :active_user, :nickname

  has_many :shifts

  scope :active_users, -> {where(active_user: true)}
  scope :inactive_users, -> {where(active_user: false)}
  scope :non_confirmed_users, -> {where(confirmed: false)}

  scope :rookies, -> {where("start_year = #{SysConfig.first.season_year} and active_user = true")}
  scope :group1, -> {where("(start_year < ?) and (start_year >= ?) and (active_user = true)", SysConfig.first.season_year, SysConfig.first.group_1_year)}
  scope :group2, -> {where("(start_year < ?) and (start_year >= ?) and (active_user = true)", SysConfig.first.group_1_year, SysConfig.first.group_2_year)}
  scope :group3, -> {where("(start_year < ?) and (active_user = true)", SysConfig.first.group_2_year)}

  before_destroy :clear_shifts_on_destroy

  def seniority
    if self.active_user != true
      retval = 'InActive'
    else
      config = SysConfig.first
      retval = "Rookie" if self.start_year == config.season_year
      retval = "Freshman" if (self.start_year == config.season_year) && (self.start_year < config.group_1_year)
      retval = "Junior" if (self.start_year >= config.group_2_year) && (self.start_year < config.group_1_year)
      retval = "Senior" if self.start_year < config.group_2_year
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
    self.start_year == SysConfig.first.season_year
  end

  def group_3?
    self.start_year < SysConfig.first.group_2_year
  end

  def group_2?
    (self.start_year >= SysConfig.first.group_2_year) && (self.start_year < SysConfig.first.group_1_year)
  end

  def group_1?
    (self.start_year >= SysConfig.first.group_1_year) && (self.start_year != SysConfig.first.season_year)
  end

  def shadow_count
    iCnt = 0
    self.shifts.each do |s|
      iCnt += 1 if s.shadow?
    end
    iCnt
  end

  def round_one_type_count
    iCnt = 0
    self.shifts.each do |s|
      iCnt += 1 if s.round_one_rookie_shift?
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

  private

  def clear_shifts_on_destroy
    self.shifts.each do |s|
      s.user_id = nil
      s.save
    end
  end
end
