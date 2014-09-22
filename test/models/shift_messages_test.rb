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

  def test_report_shift_count_after_selection_rounds
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
    config.save

    @group1_user.shift_status_message.include?("0 of 18 Shifts Selected.  You need to pick 18").must_equal true
    @group2_user.shift_status_message.include?("0 of 18 Shifts Selected.  You need to pick 18").must_equal true
    @group3_user.shift_status_message.include?("0 of 18 Shifts Selected.  You need to pick 18").must_equal true
  end

  def test_show_selection_counts_for_round_one
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 1)
    config.save
    shifts = Shift.find_all_by_shift_type_id(@p1.id)
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        break if u.shifts.length > 5
        if u.shifts.length < 5
          u.shift_status_message.include?("#{u.shifts.length} of 5 Shifts Selected.  You need to pick #{5 - u.shifts.length}").must_equal true
        else
          u.shift_status_message.include?("All required shifts selected for round 1. (5 of 5)").must_equal true
        end
        u.shifts << s
      end
    end
  end

  def test_show_selection_counts_for_round_two
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
    config.save
    shifts = Shift.find_all_by_shift_type_id(@p1.id)
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length > 10
        if u.shifts.length < 10
          u.shift_status_message.include?("#{u.shifts.length} of 10 Shifts Selected.  You need to pick #{10 - u.shifts.length}").must_equal true
        else
          u.shift_status_message.include?("All required shifts selected for round 2. (10 of 10)").must_equal true
        end
      end
    end
  end

  def test_show_selection_counts_for_round_three
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
    config.save
    shifts = Shift.find_all_by_shift_type_id(@p1.id)
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length > 15
        if u.shifts.length < 15
          u.shift_status_message.include?("#{u.shifts.length} of 15 Shifts Selected.  You need to pick #{15 - u.shifts.length}").must_equal true
        else
          u.shift_status_message.include?("All required shifts selected for round 3. (15 of 15)").must_equal true
        end
      end
    end
  end

  def test_show_selection_counts_for_round_four
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
    config.save
    shifts = Shift.find_all_by_shift_type_id(@p1.id)
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length > 18
        if u.shifts.length < 18
          u.shift_status_message.include?("#{u.shifts.length} of 18 Shifts Selected.  You need to pick #{18 - u.shifts.length}").must_equal true
        else
          u.shift_status_message.include?("All required shifts selected for round 4. (18 of 18)").must_equal true
        end
      end
    end
  end

  def test_show_proper_message_after_round_four_with_holiday
    holiday_shift = Shift.last
    holiday_shift.shift_date = HOLIDAYS[0]
    holiday_shift.save

    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 5)
    config.save
    shifts = Shift.find_all_by_shift_type_id(@p1.id)
    [@group1_user, @group2_user, @group3_user].each do |u|
      u.shifts << holiday_shift

      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length >= 18

        msgs = u.shift_status_message
        u.shift_status_message.include?("#{u.shifts.length} of 18 Shifts Selected.  You need to pick #{18 - u.shifts.length}").must_equal true
        msgs.count.must_equal 1
      end
      msgs = u.shift_status_message
      msgs.include?("All required shifts selected.").must_equal true
      msgs.include?("You are currently in <strong>round 5</strong>.").must_equal false
      msgs.count.must_equal 1
    end
  end

  def test_show_proper_message_after_round_four_without_holiday
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 5)
    config.save
    shifts = Shift.find_all_by_shift_type_id(@p1.id)
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        # Don't allow a holiday shift
        next if HOLIDAYS.include? s.shift_date

        u.shifts << s
        break if u.shifts.length >= 18
        msgs = u.shift_status_message
        u.shift_status_message.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
        u.shift_status_message.include?("#{u.shifts.length} of 18 Shifts Selected.  You need to pick #{18 - u.shifts.length}").must_equal true
        msgs.count.must_equal 2
      end

      msgs = u.shift_status_message
      msgs.include?("All required shifts selected.").must_equal false
      msgs.include?("You are currently in <strong>round 5</strong>.").must_equal false
      msgs.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
      msgs.count.must_equal 1
    end
  end
end