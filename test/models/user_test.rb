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

require "test_helper"

class UserTest < ActiveSupport::TestCase
  before do
    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @team_leader = User.find_by_name('teamlead')
    @user = User.create(name: 'test user', email: 'user@example.com')

    @tl = ShiftType.find_by_short_name('TL')
    @sh = ShiftType.find_by_short_name('SH')

    @p1 = ShiftType.find_by_short_name('P1')
    @p2 = ShiftType.find_by_short_name('P2')
    @p3 = ShiftType.find_by_short_name('P3')
    @p4 = ShiftType.find_by_short_name('P4')
    @g1 = ShiftType.find_by_short_name('G1weekend')
    @g2 = ShiftType.find_by_short_name('G2weekend')
    @g3 = ShiftType.find_by_short_name('G3weekend')
    @g4 = ShiftType.find_by_short_name('G4weekend')
    @g1f = ShiftType.find_by_short_name('G1friday')
    @g2f = ShiftType.find_by_short_name('G2friday')
    @g3f = ShiftType.find_by_short_name('G3friday')
    @g4f = ShiftType.find_by_short_name('G4friday')
    @g5 = ShiftType.find_by_short_name('G5')
    @c1 = ShiftType.find_by_short_name('C1')
    @c2 = ShiftType.find_by_short_name('C2')
    @c3 = ShiftType.find_by_short_name('C3weekend')
    @c4 = ShiftType.find_by_short_name('C4weekend')
    @bg = ShiftType.find_by_short_name('BG')

    @start_date = (Date.today()  + 20.days)
  end

  describe 'tour ratio' do
    before do
      @p2.tasks = "peruvian morning tour"
      @p2.save
    end

    it 'should not count meetings in calc' do
      mtg = FactoryGirl.create(:shift_type, 'short_name' => 'M1')
      shift = FactoryGirl.create(:shift, :shift_type_id => mtg.id, :shift_date => Date.today)
      @user.shifts << shift
      @user.tour_ratio.must_equal 0
    end

    it 'should have a 0 ratio if user has no shifts' do
      @user.shifts.size.must_equal 0
      @user.tour_ratio.must_equal 0
    end

    it 'should have a ratio of 100 if all shifts are tours' do
      (1..10).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 100
    end

    it 'should have a ratio of 50 if half of the shifts are tours' do
      (1..10).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
        ashift = FactoryGirl.create(:shift, :shift_type_id => @c4.id, :shift_date => Date.today - 1.month - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 50
    end

    it 'should have a ratio of 25 if a quarter of the shifts are tours' do
      (1..5).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
      end
      (1..15).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @c4.id, :shift_date => Date.today - 1.month - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 25
    end

    it 'should have a ratio of 75 is 3 quarters of the shifts are tours' do
      (1..15).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
      end
      (1..5).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @c4.id, :shift_date => Date.today - 1.month - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 75
    end
  end

  describe "seniority" do
    it "should be Supervisor for John Cotter" do
      @user.name = 'John Cotter'
      @user.seniority.must_equal 'Supervisor'
    end

    it 'should be Rookie for rookie user' do
      @rookie_user.seniority.must_equal 'Rookie'
    end

    it 'should be Group 3 (Newer) for first year user' do
      @group3_user.seniority.must_equal 'Group 3 (Newer)'
    end

    it 'should be Group 2 (Middle) for middle group users' do
      @group2_user.seniority.must_equal 'Group 2 (Middle)'
    end

    it 'should be Group 1 (Senior) for senior user' do
      @group1_user.seniority.must_equal 'Group 1 (Senior)'
    end

    it 'should be Rookie for rookie user' do
      @rookie_user.seniority.must_equal 'Rookie'
    end
  end

  describe 'seniority Group' do
    it "should return correct group values for each user" do
      @user.active_user = false
      @user.seniority_group.must_equal 5

      @group1_user.seniority_group.must_equal 1
      @group2_user.seniority_group.must_equal 2
      @group3_user.seniority_group.must_equal 3
      @rookie_user.seniority_group.must_equal 4
    end
  end
end
