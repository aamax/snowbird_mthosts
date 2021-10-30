require "test_helper"

class NonRookieMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @p1 = ShiftType.find_by_short_name('P1weekend')
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
        shift = FactoryBot.create(:shift, shift_date: h, shift_type_id: @p1.id)

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

  def test_round_one_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 1)
    @sys_config.save

    @group2_user.shift_status_message.include?("2 of 7 Shifts Selected.  You need to pick 5").must_equal true

    num = 2
    Shift.all.each do |s|
      if s.can_select(@group2_user, HostUtility.can_select_params_for(@group2_user))
        @group2_user.shifts << s
        num += 1
        if num < 7 then
          @group2_user.shift_status_message.include?("#{num} of 7 Shifts Selected.  You need to pick #{7 - num}").must_equal true
        else
          @group2_user.shift_status_message.include?("All required shifts selected for round 1. (7 of 7)").must_equal true
        end
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

    @group3_user.shift_status_message.include?("2 of 12 Shifts Selected.  You need to pick 10").must_equal true

    num = 2
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
        num += 1
        if num < 12 then
          @group3_user.shift_status_message.include?("#{num} of 12 Shifts Selected.  You need to pick #{12 - num}").must_equal true
        else
          @group3_user.shift_status_message.include?("All required shifts selected for round 2. (12 of 12)").must_equal true
        end
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

    @group3_user.shift_status_message.include?("2 of 17 Shifts Selected.  You need to pick 15").must_equal true

    num = 1
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
        num += 1
        if num < 12 then
          @group3_user.shift_status_message.include?("#{num} of 17 Shifts Selected.  You need to pick #{17 - num}").must_equal true
        else
          @group3_user.shift_status_message.include?("All required shifts selected for round 3. (17 of 17)").must_equal true
        end
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

    @group3_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true

    num = 1
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
        num += 1
        if num < 12 then
          @group3_user.shift_status_message.include?("#{num} of 20 Shifts Selected.  You need to pick #{20 - num}").must_equal true
        else
          @group3_user.shift_status_message.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
        end
      end
    end
    @group3_user.shifts.count.must_equal 20
    msgs = @group3_user.shift_status_message
    msgs.include?("You are currently in <strong>round 4</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
  end

  def test_after_bingo_status_message
    # TODO implement test for after bingo messages

  end

end

