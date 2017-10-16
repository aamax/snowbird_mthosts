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

  # describe "shadow date" do
  #   before  do
  #     @sys_config.bingo_start_date = (Date.today -  9.days)
  #     @sys_config.save!
  #
  #     Shift.all.each do |s|
  #       if (s.can_select(@rookie_user) == true)
  #         @rookie_user.shifts << s
  #         @last_date = s.shift_date if s.shadow? && (@last_date.nil? || @last_date < s.shift_date)
  #       end
  #     end
  #   end
  #
  #   it "should return correct shadow date" do
  #     @last_date.must_equal @rookie_user.last_shadow
  #   end
  # end

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

  describe 'shift message tests' do
    describe 'rookie users' do
      describe 'holidays' do
        def test_show_need_a_holiday_if_not_picked
          [@rookie_user].each do |u|
            u.has_holiday_shift?.must_equal false
            u.shift_status_message.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
          end
        end

        def test_show_need_a_holiday_if_picked
          [@rookie_user].each do |u|
            HOLIDAYS.each do |h|
              shift = FactoryGirl.create(:shift, shift_date: h, shift_type_id: @g1.id)
              u.shifts << shift
              u.has_holiday_shift?.must_equal true
              assert_operator(HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user), :<=, 6)
              u.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
            end
          end
        end

        def test_show_need_a_holiday_if_picked_after_bingo
          shift = FactoryGirl.create(:shift, shift_date: HOLIDAYS[0], shift_type_id: @g1.id)
          @rookie_user.shifts << shift
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
          @sys_config.save
          @rookie_user.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
        end
      end

      # def test_shadows_selected
      #   @sys_config.bingo_start_date = Date.today + 2.days
      #   @sys_config.save
      #   shadow_count = @rookie_user.shadow_count
      #   shadow_count.must_equal 0
      #   @rookie_user.shift_status_message.include?("0 of 4 selected.  Need 4 Shadow Shifts.").must_equal true
      #   Shift.all.each do |s|
      #     if s.can_select(@rookie_user)
      #       @rookie_user.shifts << s
      #       shadow_count = @rookie_user.shadow_count
      #       if  (shadow_count >= SHADOW_COUNT)
      #         @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
      #       else
      #         @rookie_user.shift_status_message.include?("#{shadow_count} of #{SHADOW_COUNT} selected.  Need #{SHADOW_COUNT - shadow_count} Shadow Shifts.").must_equal true
      #       end
      #     end
      #     break if  (shadow_count >= SHADOW_COUNT)
      #   end
      # end

      # def test_round_two_status_messages
      #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
      #   @sys_config.save
      #   Shift.all.each do |s|
      #     if s.can_select(@rookie_user)
      #       @rookie_user.shifts << s
      #     end
      #   end
      #   @rookie_user.shifts.count.must_equal 14
      #   msgs = @rookie_user.shift_status_message
      #   # msgs.include?("All Shadow Shifts Selected.").must_equal true
      #   msgs.include?("All required shifts selected for round 2. (14 of 14)").must_equal true
      #   msgs.include?("You are currently in <strong>round 2</strong>.").must_equal true
      #   msgs.include?("You have 14 shifts selected.").must_equal true
      # end
      #
      # def test_round_three_status_messages
      #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
      #   @sys_config.save
      #   Shift.all.each do |s|
      #     if s.can_select(@rookie_user)
      #       @rookie_user.shifts << s
      #     end
      #   end
      #   @rookie_user.shifts.count.must_equal 19
      #   msgs = @rookie_user.shift_status_message
      #   # msgs.include?("All Shadow Shifts Selected.").must_equal true
      #   msgs.include?("All required shifts selected for round 3. (19 of 19)").must_equal true
      #   msgs.include?("You are currently in <strong>round 3</strong>.").must_equal true
      #   msgs.include?("You have 19 shifts selected.").must_equal true
      # end
      #
      # def test_round_four_status_messages
      #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 4)
      #   @sys_config.save
      #   Shift.all.each do |s|
      #     if s.can_select(@rookie_user)
      #       @rookie_user.shifts << s
      #     end
      #   end
      #   @rookie_user.shifts.count.must_equal 20
      #   msgs = @rookie_user.shift_status_message
      #
      #   # msgs.include?("All Shadow Shifts Selected.").must_equal true
      #   msgs.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
      #   msgs.include?("You are currently in <strong>round 4</strong>.").must_equal true
      #   msgs.include?("You have 20 shifts selected.").must_equal true
      # end
      #
      # def test_round_five_status_messages
      #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
      #   @sys_config.save
      #   Shift.all.each do |s|
      #     if s.can_select(@rookie_user)
      #       @rookie_user.shifts << s
      #     end
      #   end
      #
      #   @rookie_user.shifts.count.must_equal 29
      #
      #   msgs = @rookie_user.shift_status_message
      #   # msgs.include?("All Shadow Shifts Selected.").must_equal true
      #   msgs.include?("You have 29 shifts selected.").must_equal true
      # end
    end

    describe 'general users' do
      describe 'holidays' do
        def test_show_need_a_holiday_if_not_picked
          [@group1_user].each do |u|
            u.has_holiday_shift?.must_equal false
            u.shift_status_message.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
          end
        end

        def test_show_need_a_holiday_if_picked
          [@group1_user].each do |u|
            HOLIDAYS.each do |h|
              shift = FactoryGirl.create(:shift, shift_date: h, shift_type_id: @g1.id)
              u.shifts << shift
              u.has_holiday_shift?.must_equal true
              assert_operator(HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @group1_user), :<=, 6)
              u.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
            end
          end
        end

        def test_show_need_a_holiday_if_picked_after_bingo
          shift = FactoryGirl.create(:shift, shift_date: HOLIDAYS[0], shift_type_id: @g1.id)
          @group1_user.shifts << shift
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 5)
          @sys_config.save
          @group1_user.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
        end
      end

      # def test_round_two_status_messages
      #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 2)
      #   @sys_config.save
      #   Shift.all.each do |s|
      #     if s.can_select(@group1_user)
      #       @group1_user.shifts << s
      #     end
      #   end
      #   @group1_user.shifts.count.must_equal 12
      #   msgs = @group1_user.shift_status_message
      #   msgs.include?("All required shifts selected for round 2. (12 of 12)").must_equal true
      #   msgs.include?("You are currently in <strong>round 2</strong>.").must_equal true
      #   msgs.include?("You have 12 shifts selected.").must_equal true
      # end

      # def test_round_three_status_messages
      #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 3)
      #   @sys_config.save
      #   Shift.all.each do |s|
      #     if s.can_select(@group2_user)
      #       @group2_user.shifts << s
      #     end
      #   end
      #   @group2_user.shifts.count.must_equal 17
      #   msgs = @group2_user.shift_status_message
      #   msgs.include?("All required shifts selected for round 3. (17 of 17)").must_equal true
      #   msgs.include?("You are currently in <strong>round 3</strong>.").must_equal true
      #   msgs.include?("You have 17 shifts selected.").must_equal true
      # end

      def test_round_four_status_messages
        @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
        @sys_config.save
        Shift.all.each do |s|
          if s.can_select(@group3_user)
            @group3_user.shifts << s
          end
        end
        @group3_user.shifts.count.must_equal 20
        msgs = @group3_user.shift_status_message

        msgs.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
        msgs.include?("You are currently in <strong>round 4</strong>.").must_equal true
        msgs.include?("You have 20 shifts selected.").must_equal true
      end

      # def test_round_five_status_messages
      #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 5)
      #   @sys_config.save
      #   Shift.all.each do |s|
      #     if s.can_select(@group3_user)
      #       @group3_user.shifts << s
      #     end
      #   end
      #   @group3_user.shifts.count.must_equal 27
      #
      #   msgs = @group3_user.shift_status_message
      #   msgs.include?("You have 27 shifts selected.").must_equal true
      # end
    end
  end
end
