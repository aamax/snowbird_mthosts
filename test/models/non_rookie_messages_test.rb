require "test_helper"

class NonRookieMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @p1 = ShiftType.find_by_short_name('P1weekend')
    @trainer = ShiftType.find_by_short_name('TR')
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

    @group1_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group1_user, 1) -1 }.").must_equal true
    @group2_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group2_user, 1) - 1}.").must_equal true
    @group3_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group3_user, 1) - 1}.").must_equal true
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

    msgs = @group2_user.shift_status_message
    msgs.include?("You are currently in <strong>round 1</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 1. (7 of 7)").must_equal true
    @group2_user.shifts.count.must_equal 7
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
    msgs = @group3_user.shift_status_message
    msgs.include?("You are currently in <strong>round 2</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 2. (12 of 12)").must_equal true
    @group3_user.shifts.count.must_equal 12
  end

  def test_round_three_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
    @sys_config.save

    @group3_user.shift_status_message.include?("2 of 17 Shifts Selected.  You need to pick 15").must_equal true

    num = 0
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
        num += 1
        if num < 15 then
          @group3_user.shift_status_message.include?("#{num + 2} of 17 Shifts Selected.  You need to pick #{17 - (num + 2)}").must_equal true
        else
          @group3_user.shift_status_message.include?("All required shifts selected for round 3. (17 of 17)").must_equal true
        end
      end
    end
    msgs = @group3_user.shift_status_message
    msgs.include?("You are currently in <strong>round 3</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 3. (17 of 17)").must_equal true
    @group3_user.shifts.count.must_equal 17
  end

  def test_round_four_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
    @sys_config.save

    @group3_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true

    num = 0
    Shift.all.each do |s|
      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
        num += 1
        if num < 18 then
          @group3_user.shift_status_message.include?("#{num + 2} of 20 Shifts Selected.  You need to pick #{20 - (num + 2)}").must_equal true
        else
          @group3_user.shift_status_message.include?("You have at least 20 shifts selected").must_equal true
        end
      end
    end
    msgs = @group3_user.shift_status_message
    msgs.include?("You are currently in <strong>round 4</strong>.").must_equal true
    msgs.include?("You have at least 20 shifts selected").must_equal true
    @group3_user.shifts.count.must_equal 20
  end

  def test_after_bingo_status_message
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 6)
    @sys_config.save

    @group2_user.shift_status_message.include?("Shift Selection Bingo is over...").must_equal true
    @group2_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true

    num = 0
    Shift.all.each do |s|
      if s.can_select(@group2_user, HostUtility.can_select_params_for(@group2_user))
        @group2_user.shifts << s
        num += 1

        if num < 18 then
          @group2_user.shift_status_message.include?("#{num + 2} of 20 Shifts Selected.  You need to pick #{20 - (num + 2)}").must_equal true
        else
          @group2_user.shift_status_message.include?("You have at least 20 shifts selected").must_equal true
        end
      end
    end
    msgs = @group2_user.shift_status_message

    msgs.include?("Shift Selection Bingo is over...").must_equal true
    msgs.include?("You have at least 20 shifts selected").must_equal true
    (@group2_user.shifts.count > 20).must_equal true
  end

  def test_ogomt_shifts_do_not_count_for_bingo

  end

  def test_trainer_shifts_do_not_count_for_bingo
    bingo_date = HostUtility.bingo_start_for_round(@group3_user, 2)
    @sys_config.bingo_start_date = bingo_date
    @sys_config.save

    @group3_user.add_role :trainer

    trainer_shift = FactoryBot.create(:shift, shift_date: bingo_date + 15.days, shift_type: @trainer)
    @group3_user.shifts << trainer_shift
    num = 2
    Shift.all.each do |s|
      next if s.is_tour? || @group3_user.is_working?(s.shift_date) || s.meeting? || s.team_leader? || s.trainer?

      if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
        @group3_user.shifts << s
        num += 1
      end
    end
    msgs = @group3_user.shift_status_message

    msgs.include?("You are currently in <strong>round 2</strong>.").must_equal true
    msgs.include?("All required shifts selected for round 2. (13 of 13)").must_equal true
    @group3_user.shifts.count.must_equal 13
  end

  def test_tour_quota_messages
    bingo_date = HostUtility.bingo_start_for_round(@group3_user, 2)
    @sys_config.bingo_start_date = bingo_date
    @sys_config.save

    msgs = @group3_user.shift_status_message

    msgs.include?("You do not have any tour shifts (minimum of 2).").must_equal true

    shift = FactoryBot.create(:shift, shift_date: bingo_date + 30.days, shift_type_id: @p1.id)
    @group3_user.shifts << shift
    msgs = @group3_user.shift_status_message

    msgs.include?("You have 1 tour shifts.").must_equal true

    shift = FactoryBot.create(:shift, shift_date: bingo_date + 31.days, shift_type_id: @p1.id)
    @group3_user.shifts << shift
    shift = FactoryBot.create(:shift, shift_date: bingo_date + 32.days, shift_type_id: @p1.id)
    @group3_user.shifts << shift
    msgs = @group3_user.shift_status_message

    msgs.include?("You have 3 tour shifts.").must_equal true
  end
end

