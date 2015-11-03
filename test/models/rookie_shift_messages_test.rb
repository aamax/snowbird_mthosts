require "test_helper"

class RookieMessageTest < ActiveSupport::TestCase

  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @p1 = ShiftType.find_by_short_name('P1')
    @g1 = ShiftType.find_by_short_name('G1weekend')
    @sh = ShiftType.find_by_short_name('SH')
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

  def test_shadows_selected
    @sys_config.bingo_start_date = Date.today + 2.days
    @sys_config.save
    shadow_count = @rookie_user.shadow_count
    shadow_count.must_equal 0
    @rookie_user.shift_status_message.include?("0 of 4 selected.  Need 4 Shadow Shifts.").must_equal true
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
        shadow_count = @rookie_user.shadow_count
        if  (shadow_count >= SHADOW_COUNT)
          @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
        else
          @rookie_user.shift_status_message.include?("#{shadow_count} of #{SHADOW_COUNT} selected.  Need #{SHADOW_COUNT - shadow_count} Shadow Shifts.").must_equal true
        end
      end
      break if  (shadow_count >= SHADOW_COUNT)
    end
  end

  def test_round_two_can_select_message
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 10
    msgs = @rookie_user.shift_status_message
    msgs.include?("All Shadow Shifts Selected.").must_equal true
    msgs.include?("All required shifts selected for round 2. (10 of 10)").must_equal true
  end

  def test_after_bingo_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 4)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 20
    @rookie_user.shadow_count.must_equal SHADOW_COUNT
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
    @sys_config.save

    msgs = @rookie_user.shift_status_message
    msgs.include?("All Shadow Shifts Selected.").must_equal true
  end

end