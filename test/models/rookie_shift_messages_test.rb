require "test_helper"

class RookieMessageTest < ActiveSupport::TestCase

  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @p1 = ShiftType.find_by_short_name('P1')
    @g1 = ShiftType.find_by_short_name('G1')
  end

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
        u.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
      end
    end
  end

  def test_shift_picking_before_round_one
    config = SysConfig.first
    config.bingo_start_date = Date.today + 10.days
    config.save

    @rookie_user.shift_status_message.include?("").must_equal true
  end

  def test_report_shift_count_after_selection_rounds
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 6)
    config.save

    @group1_user.shift_status_message.include?("0 of 16 Shifts Selected.  You need to pick 16").must_equal true
    @group2_user.shift_status_message.include?("0 of 16 Shifts Selected.  You need to pick 16").must_equal true
    @group3_user.shift_status_message.include?("0 of 16 Shifts Selected.  You need to pick 16").must_equal true
  end

end