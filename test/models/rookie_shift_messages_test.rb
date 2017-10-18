require "test_helper"

class RookieMessageTest < ActiveSupport::TestCase
  def create_t1_shifts
    t1type = FactoryGirl.create(:shift_type, short_name: 'T1')
    (1..5).each do |n|
      FactoryGirl.create(:shift, shift_date: Date.today + n.days, shift_type_id: t1type.id)
    end
  end

  def create_t2andt3_shifts
    t2type = FactoryGirl.create(:shift_type, short_name: 'T2')
    t3type = FactoryGirl.create(:shift_type, short_name: 'T3')
    (1..5).each do |n|
      FactoryGirl.create(:shift, shift_date: Date.today + 6.days + n.days, shift_type_id: t2type.id)
    end
    (1..5).each do |n|
      FactoryGirl.create(:shift, shift_date: Date.today + 12.days + n.days, shift_type_id: t3type.id)
    end
  end

  def select_rookie_training_shifts
    create_t1_shifts
    create_t2andt3_shifts
    @rookie_user.shifts << Shift.where("short_name = 'T1'").first
    @rookie_user.shifts << Shift.where("short_name = 'T2'").first
    @rookie_user.shifts << Shift.where("short_name = 'T3'").first
  end

  def create_late_season_tours
    start_date = rookie_tour_date
    (1..5).each do |n|
      FactoryGirl.create(:shift, shift_date: start_date + n.days, shift_type_id: @p1.id)
    end
  end

  def create_early_season_tours
    start_date = rookie_tour_date - 3.months
    (1..5).each do |n|
      FactoryGirl.create(:shift, shift_date: start_date + n.days, shift_type_id: @p1.id)
    end
  end

  def rookie_tour_date
    yr = Date.today.year + 1
    Date.parse("#{yr}-02-01")
  end

  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @p1 = ShiftType.find_by_short_name('P1')
    @g1 = ShiftType.find_by_short_name('G1weekend')
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

  def test_no_training_shifts_selected
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 0)
    @sys_config.save

    msgs = @rookie_user.shift_status_message
    msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
    msgs.include?("You have 4 of 7 shifts selected").must_equal true
    msgs.include?("You have not selected any training shifts").must_equal true
  end

  def test_T1_training_shift_selected
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 0)
    @sys_config.save
    create_t1_shifts
    create_t2andt3_shifts
    @rookie_user.shifts << Shift.where("short_name = 'T1'").first

    msgs = @rookie_user.shift_status_message
    msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
    msgs.include?("You have 5 of 7 shifts selected").must_equal true
    msgs.include?("You need to select a T2 shift").must_equal true
  end

  def test_T2_training_shift_not_selected
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 0)
    @sys_config.save
    create_t1_shifts
    create_t2andt3_shifts
    @rookie_user.shifts << Shift.where("short_name = 'T1'").first
    @rookie_user.shifts << Shift.where("short_name = 'T3'").first

    msgs = @rookie_user.shift_status_message
    msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
    msgs.include?("You have 6 of 7 shifts selected").must_equal true
    msgs.include?("You need to select a T2 shift").must_equal true
  end

  def test_T3_training_shift_not_selected
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 0)
    @sys_config.save
    create_t1_shifts
    create_t2andt3_shifts
    @rookie_user.shifts << Shift.where("short_name = 'T1'").first
    @rookie_user.shifts << Shift.where("short_name = 'T2'").first

    msgs = @rookie_user.shift_status_message
    msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
    msgs.include?("You have 6 of 7 shifts selected").must_equal true
    msgs.include?("You need to select a T3 shift").must_equal true
  end

  def test_training_shifts_selected
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 0)
    @sys_config.save
    select_rookie_training_shifts

    msgs = @rookie_user.shift_status_message
    msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
    msgs.include?("You have 7 of 7 shifts selected").must_equal true
    msgs.include?("You have selected all your training shifts").must_equal true
  end

  def test_after_bingo_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 6)
    @sys_config.save
    select_rookie_training_shifts

    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    (@rookie_user.shifts.count > 20).must_equal true

    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
    @sys_config.save

    msgs = @rookie_user.shift_status_message
    msgs.include?("You have at least 20 shifts selected.")
  end

  def test_round_one_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
    @sys_config.save
    select_rookie_training_shifts
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 12
    msgs = @rookie_user.shift_status_message
    msgs.include?("You have selected all your training shifts").must_equal true
    msgs.include?("You are currently in <strong>round 1</strong>.").must_equal true
    msgs.include?("You have 12 of 12 shifts selected").must_equal true
  end

  def test_round_two_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
    @sys_config.save
    select_rookie_training_shifts
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 17
    msgs = @rookie_user.shift_status_message
    msgs.include?("You have selected all your training shifts").must_equal true
    msgs.include?("You are currently in <strong>round 2</strong>.").must_equal true
    msgs.include?("You have 17 of 17 shifts selected").must_equal true
  end

  def test_round_three_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
    @sys_config.save
    select_rookie_training_shifts
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 20
    msgs = @rookie_user.shift_status_message
    msgs.include?("You have selected all your training shifts").must_equal true
    msgs.include?("You are currently in <strong>round 3</strong>.").must_equal true
    msgs.include?("You have 20 shifts selected").must_equal true
  end

  def test_round_four_status_messages
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 4)
    @sys_config.save
    select_rookie_training_shifts
    Shift.all.each do |s|
      if s.can_select(@rookie_user)
        @rookie_user.shifts << s
      end
    end
    @rookie_user.shifts.count.must_equal 20
    msgs = @rookie_user.shift_status_message
    msgs.include?("You have selected all your training shifts").must_equal true
    msgs.include?("You are currently in <strong>round 4</strong>.").must_equal true
    msgs.include?("You have 20 shifts selected").must_equal true
  end
end