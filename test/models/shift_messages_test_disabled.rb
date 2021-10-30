require "test_helper"

class UserMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @p1 = ShiftType.find_by_short_name('P1')
  end





  def test_after_bingo_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
    @sys_config.save

    Shift.all.each do |s|
      if s.can_select(@group1_user, HostUtility.can_select_params_for(@group1_user))
        @group1_user.shifts << s
      end
    end

    assert_operator(20, :<, @group1_user.shifts.count)
    msgs = @group1_user.shift_status_message
    msgs.include?("You have at least 20 shifts selected").must_equal true
  end


  def test_round_two_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
      end
    end
    @group3_user.shifts.count.must_equal 12
    msgs = @group3_user.shift_status_message
    msgs.include?("You are currently in <strong>round 2</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 2. (12 of 12)").must_equal true
  end

  def test_round_three_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
      end
    end
    @group3_user.shifts.count.must_equal 17
    msgs = @group3_user.shift_status_message
    msgs.include?("You are currently in <strong>round 3</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 3. (17 of 17)").must_equal true
  end

  def test_round_four_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
      end
    end
    @group3_user.shifts.count.must_equal 20
    msgs = @group3_user.shift_status_message
    msgs.include?("You are currently in <strong>round 4</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
  end

  def test_report_shift_count_after_selection_rounds
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
    config.save

    @group1_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
    @group2_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
    @group3_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
  end
end