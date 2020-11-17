require "test_helper"

class TeamleaderMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @teamleader = User.find_by_name('g1')

    @teamleader.add_role :team_leader
    @tltype = ShiftType.find_by(short_name: 'TL')
    @a1type = ShiftType.find_by(short_name: 'A1')
    @octype = ShiftType.find_by(short_name: 'OC')

    (1..50).each do |n|
      FactoryBot.create(:shift, shift_type_id: @tltype.id, shift_date: Date.today + n.days)
      FactoryBot.create(:shift, shift_type_id: @a1type.id, shift_date: Date.today + n.days)
      FactoryBot.create(:shift, shift_type_id: @octype.id, shift_date: Date.today + n.days)
      FactoryBot.create(:shift, shift_type_id: @octype.id, shift_date: Date.today + n.days + (n * 2).days)
    end
  end

  def test_show_teamleader_shift_count_pre_bingo
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 0)
    @sys_config.save

    Shift.all.each do |s|
      if s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    # can have 19 shifts total
    assert_equal(19, @teamleader.shifts.count)

    counts = Hash.new 0
    @teamleader.shifts.map(&:short_name).each {|s| counts[s] += 1 }
    a1_count = counts['A1']
    oc_count = counts['OC']
    tl_count = counts['TL']

    assert_equal(7, tl_count)
    assert_equal(10, oc_count)
    assert_equal(0, a1_count)

    msgs = @teamleader.shift_status_message

    msgs.include?("7 team leader shifts selected").must_equal true
    msgs.include?("10 On Call shifts selected").must_equal true
    msgs.include?("All Required Shifts Selected")
  end

  def test_show_shift_count_in_round_3
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 3)
    @sys_config.save

    Shift.all.each do |s|
      if s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    # can have 19 shifts total
    assert_equal(19, @teamleader.shifts.count)

    counts = Hash.new 0
    @teamleader.shifts.map(&:short_name).each {|s| counts[s] += 1 }
    a1_count = counts['A1']
    oc_count = counts['OC']
    tl_count = counts['TL']

    assert_equal(7, tl_count)
    assert_equal(10, oc_count)
    assert_equal(0, a1_count)

    msgs = @teamleader.shift_status_message

    msgs.include?("7 team leader shifts selected").must_equal true
    msgs.include?("10 On Call shifts selected").must_equal true
    msgs.include?("All Required Shifts Selected")
  end

  def test_show_shift_count_post_bingo
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 6)
    @sys_config.save

    Shift.all.each do |s|
      if s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    Shift.where("short_name = 'OC'").each do |s|
      if s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    # can have 19 shifts total
    assert_equal(103, @teamleader.shifts.count)

    counts = Hash.new 0
    @teamleader.shifts.map(&:short_name).each {|s| counts[s] += 1 }
    a1_count = counts['A1']
    oc_count = counts['OC']
    tl_count = counts['TL']

    assert_equal(41, tl_count)
    assert_equal(52, oc_count)
    assert_equal(8, a1_count)

    msgs = @teamleader.shift_status_message

    msgs.include?("41 team leader shifts selected").must_equal(true, msgs)
    msgs.include?("52 On Call shifts selected").must_equal(true, msgs)
    msgs.include?("All Required Shifts Selected").must_equal(true, msgs)
  end
end
