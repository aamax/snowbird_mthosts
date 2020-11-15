require "test_helper"

class TeamleaderMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @teamleader = User.find_by_name('g1')

    @teamleader.add_role :team_leader
    @tltype = ShiftType.find_by(short_name: 'TL')

    (1..50).each do |n|
      FactoryBot.create(:shift, shift_type_id: @tltype.id, shift_date: Date.today + n.days)
    end
  end

  def test_show_teamleader_shift_count_pre_bingo
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 0)
    @sys_config.save

    Shift.all.each do |s|
      if s.team_leader? && s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    assert_equal(9, @teamleader.shifts.count)
    assert_equal(7, @teamleader.team_leader_shift_count)
    msgs = @teamleader.shift_status_message
    msgs.include?("7 team leader shifts selected").must_equal true
  end

  def test_show_shift_count_in_round_3
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 3)
    @sys_config.save

    Shift.all.each do |s|
      if s.team_leader? && s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    assert_equal(9, @teamleader.shifts.count)
    assert_equal(7, @teamleader.team_leader_shift_count)
    msgs = @teamleader.shift_status_message
    msgs.include?("7 team leader shifts selected").must_equal(true, "#{msgs} was supposed to include: [7 team leader shifts selected]")
  end

  def test_show_shift_count_post_bingo
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 6)
    @sys_config.save

    Shift.all.each do |s|
      if s.team_leader? && s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    assert_equal(77, @teamleader.shifts.count)
    assert_equal(75, @teamleader.team_leader_shift_count)
    msgs = @teamleader.shift_status_message
    msgs.include?("75 team leader shifts selected").must_equal(true, "#{msgs} was supposed to include: [75 team leader shifts selected]")
  end
end
