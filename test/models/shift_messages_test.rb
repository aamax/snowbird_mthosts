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

  def test_show_need_a_holiday_if_not_picked
    [@group1_user, @group2_user, @group3_user].each do |u|
      u.has_holiday_shift?.must_equal false
      u.shift_status_message.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
    end
  end

  def test_show_need_a_holiday_if_picked
    [@group1_user, @group2_user, @group3_user].each do |u|
      HOLIDAYS.each do |h|
        shift = FactoryGirl.create(:shift, shift_date: h, shift_type_id: @p1.id)

        u.shifts << shift
        u.has_holiday_shift?.must_equal true
        u.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
      end
    end
  end

  def test_shift_picking_before_round_one
    config = SysConfig.first
    config.bingo_start_date = Date.today + 10.days
    config.save

    @group1_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group1_user, 1)}.").must_equal true
    @group2_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group2_user, 1)}.").must_equal true
    @group3_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group3_user, 1)}.").must_equal true
  end

  def test_after_bingo_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
    @sys_config.save

    Shift.all.each do |s|
      if s.can_select(@group1_user)
        @group1_user.shifts << s
      end
    end
    (@group1_user.shifts.count >= 20).must_equal true
    msgs = @group1_user.shift_status_message
    msgs.include?("You have at least 20 shifts selected").must_equal true
  end

  def test_round_one_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 1)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@group2_user)
        @group2_user.shifts << s
      end
    end
    @group2_user.shifts.count.must_equal 7
    msgs = @group2_user.shift_status_message
    msgs.include?("You are currently in <strong>round 1</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 1. (7 of 7)").must_equal true
  end

  def test_round_two_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@group3_user)
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
      if s.can_select(@group3_user)
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
      if s.can_select(@group3_user)
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