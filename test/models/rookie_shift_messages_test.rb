require "test_helper"

class RookieMessageTest < ActiveSupport::TestCase

  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @p1 = ShiftType.find_by_short_name('P1')
    @g1 = ShiftType.find_by_short_name('G1')
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
        assert_operator(HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user), :<=, 4)
        u.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
      end
    end
  end

  def test_show_need_a_holiday_if_picked_after_bingo
    shift = FactoryGirl.create(:shift, shift_date: HOLIDAYS[0], shift_type_id: @g1.id)
    @rookie_user.shifts << shift
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
    @sys_config.save
    @rookie_user.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal false
  end

  def test_shadows_selected
    @sys_config.bingo_start_date = Date.today + 2.days
    @sys_config.save
    shadow_count = @rookie_user.shadow_count
    shadow_count.must_equal 0
    @rookie_user.shift_status_message.include?("0 of 2 selected.  Need 2 Shadow Shifts.").must_equal true
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
        shadow_count = @rookie_user.shadow_count
        if  (shadow_count >= 2)
          @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
        else
          @rookie_user.shift_status_message.include?("#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts.").must_equal true
        end
      end
      break if  (shadow_count >= 2)
    end
  end

  def test_round_one_type_selected
    @sys_config.bingo_start_date = Date.today + 2.days
    @sys_config.save
    shadow_count = @rookie_user.shadow_count
    shadow_count.must_equal 0
    round_one_count = @rookie_user.round_one_type_count
    round_one_count.must_equal 0
    msgs = @rookie_user.shift_status_message
    msgs.include?("0 of 2 selected.  Need 2 Shadow Shifts.").must_equal true
    msgs.include?("0 of 5 Round One Rookie Shifts Selected.  Need 5 Rookie Shifts.").must_equal false

    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
        shadow_count = @rookie_user.shadow_count
        if  (shadow_count >= 2)
          round_one_count = @rookie_user.round_one_type_count
          msgs = @rookie_user.shift_status_message
          if round_one_count < 5
            msgs.include?("#{round_one_count} of 5 selected.  Need #{5 - round_one_count} Round 1 Rookie Shifts.").must_equal true
          else
            msgs.include?("All Round One Rookie Shifts Selected.")
          end
        end
      end
      break if  (round_one_count >= 5)
    end
  end

  def test_round_one_type_needed_with_non_round_one_selected
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
    @sys_config.save
    Shift.all.each do |s|
      next if (@rookie_user.shifts.count >= 7) && (s.short_name != @p1.short_name)

      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end

      break if (@rookie_user.shifts.count >= 8)
    end
    @rookie_user.shifts.count.must_equal 8
    @rookie_user.shifts.delete @rookie_user.shifts[4]
    last_date = @rookie_user.shifts[-1].shift_date
    last_shadow = @rookie_user.shifts[1].shift_date
    last_round_one = @rookie_user.shifts[-2].shift_date
    msgs = @rookie_user.shift_status_message
    last_date.must_equal @rookie_user.first_non_round_one_end_date
    last_shadow.must_equal @rookie_user.last_shadow
    last_round_one.must_equal @rookie_user.round_one_end_date
    4.must_equal @rookie_user.round_one_type_count
    msgs.include?("4 of 5 selected.  Need 1 Round 1 Rookie Shifts.").must_equal true
    @rookie_user.has_non_round_one?.must_equal true
    msgs.include?("Round 1 Type Shifts Only Between #{last_shadow} and #{last_date}").must_equal true
  end

  def test_round_one_type_needed_without_non_round_one_selected
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end

    @rookie_user.shifts.count.must_equal 7
    @rookie_user.shifts.delete @rookie_user.shifts[4]
    last_shadow = @rookie_user.shifts[1].shift_date
    last_round_one = @rookie_user.shifts[-1].shift_date
    msgs = @rookie_user.shift_status_message
    last_round_one.must_equal @rookie_user.round_one_end_date
    last_shadow.must_equal @rookie_user.last_shadow
    4.must_equal @rookie_user.round_one_type_count
    msgs.include?("4 of 5 selected.  Need 1 Round 1 Rookie Shifts.").must_equal true
    @rookie_user.has_non_round_one?.must_equal false
    msgs.include?("Round One Type Shifts Only After: #{@rookie_user.last_shadow.strftime("%Y-%m-%d")}").must_equal true
  end

  def test_round_one_all_shifts_picked
    @sys_config.bingo_start_date = Date.today + 2.days
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 7
    @rookie_user.shadow_count.must_equal 2
    @rookie_user.round_one_type_count.must_equal 5
    msgs = @rookie_user.shift_status_message
    msgs.include?("All Shadow Shifts Selected.").must_equal true
    msgs.include?("All Round One Rookie Shifts Selected.").must_equal true
    msgs.include?("Round 1 Type Shifts Only Between #{@rookie_user.last_shadow} and #{@rookie_user.round_one_end_date}.").must_equal true

    @sys_config.bingo_start_date = Date.today - 4.days - 1.week
    @sys_config.save
    @rookie_user.shifts.count.must_equal 7
    @rookie_user.shadow_count.must_equal 2
    @rookie_user.round_one_type_count.must_equal 5
    msgs = @rookie_user.shift_status_message
    msgs.include?("All Shadow Shifts Selected.").must_equal true
    msgs.include?("All Round One Rookie Shifts Selected.").must_equal true
    msgs.include?("Round 1 Type Shifts Only Between #{@rookie_user.last_shadow} and #{@rookie_user.round_one_end_date}.").must_equal true
  end

  def test_round_two_can_select_message
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 12
    msgs = @rookie_user.shift_status_message
    msgs.include?("All Shadow Shifts Selected.").must_equal true
    msgs.include?("All Round One Rookie Shifts Selected.").must_equal true
    msgs.include?("Round 1 Type Shifts Only Between #{@rookie_user.last_shadow} and #{@rookie_user.first_non_round_one_end_date}.").must_equal true
    msgs.include?("Any Shifts After #{@rookie_user.round_one_end_date}").must_equal true
  end

  def test_after_bingo_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 4)
    @sys_config.save
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 16
    @rookie_user.shadow_count.must_equal 2
    @rookie_user.round_one_type_count.must_equal 5
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
    @sys_config.save

    msgs = @rookie_user.shift_status_message
    msgs.include?("All Shadow Shifts Selected.").must_equal true
    msgs.include?("All Round One Rookie Shifts Selected.").must_equal true
    msgs.include?("Round 1 Type Shifts Only Between #{@rookie_user.last_shadow} and #{@rookie_user.round_one_end_date}.")
    msgs.include?("Any Shifts After #{@rookie_user.round_one_end_date}")
    msgs.include?("16 of 16 shifts selected.").must_equal true
    msgs.include?("All Required Shifts Selected.").must_equal true
  end

end