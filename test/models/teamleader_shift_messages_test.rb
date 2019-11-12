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

    (@teamleader.shifts.count == 20).must_equal true
    (@teamleader.team_leader_shift_count == 18).must_equal true
    msgs = @teamleader.shift_status_message
    msgs.include?("18 team leader shifts selected").must_equal true
  end

  def test_show_shift_count_in_round_4
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 4)
    @sys_config.save

    Shift.all.each do |s|
      if s.team_leader? && s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    (@teamleader.shifts.count == 20).must_equal true
    (@teamleader.team_leader_shift_count == 18).must_equal true
    msgs = @teamleader.shift_status_message
    msgs.include?("18 team leader shifts selected").must_equal true
  end

  def test_show_shift_count_post_bingo
    @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@teamleader, 6)
    @sys_config.save

    Shift.all.each do |s|
      if s.team_leader? && s.can_select(@teamleader, HostUtility.can_select_params_for(@teamleader))
        @teamleader.shifts << s
      end
    end

    _(@teamleader.shifts.count).must_equal 53
    _(@teamleader.team_leader_shift_count).must_equal 51
    msgs = @teamleader.shift_status_message
    _(msgs.include?("51 team leader shifts selected")).must_equal true
  end
end
