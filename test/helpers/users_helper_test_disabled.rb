require "test_helper"

# user picks shadow and round 1.  drop shadow.  message says pick shadow shifts

class UsersHelperTestDisabled < ActionView::TestCase
  before do
    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @team_leader = User.find_by_name('teamlead')

    @tl = ShiftType.find_by_short_name('TL')
    @sh = ShiftType.find_by_short_name('SH')

    @p1 = ShiftType.find_by_short_name('P1')
    @p2 = ShiftType.find_by_short_name('P2')
    @p3 = ShiftType.find_by_short_name('P3')
    @p4 = ShiftType.find_by_short_name('P4')
    @g1 = ShiftType.find_by_short_name('G1weekend')
    @g2 = ShiftType.find_by_short_name('G2weekend')
    @g3 = ShiftType.find_by_short_name('G3weekend')
    @g4 = ShiftType.find_by_short_name('G4weekend')
    @g5 = ShiftType.find_by_short_name('G5')
    @c1 = ShiftType.find_by_short_name('C1')
    @c2 = ShiftType.find_by_short_name('C2')
    @c3 = ShiftType.find_by_short_name('C3')
    @c4 = ShiftType.find_by_short_name('C4')
    @bg = ShiftType.find_by_short_name('BG')

    @start_date = (Date.today()  + 20.days)
  end

  describe "Shift Bingo Messages" do
    before do
      HostConfig.initialize_values
    end

    describe "rookie" do
      # it "should report for prior to bingo shift selections" do
      #   config = SysConfig.first
      #   config.bingo_start_date = Date.today + 2.days
      #   config.save!
      #   HostUtility.get_current_round(config.bingo_start_date, Date.today, @rookie_user).must_equal 0
      #   Shift.all.each do |s|
      #     next if @rookie_user.is_working? s.shift_date
      #     break if @rookie_user.shifts.length >= 9
      #     # shadow_count = @rookie_user.shadow_count
      #     if @rookie_user.shifts.length < SHADOW_COUNT + 4
      #       # next unless s.shadow?
      #       # @rookie_user.shift_status_message.include?("#{shadow_count} of #{SHADOW_COUNT} selected.  Need #{SHADOW_COUNT - shadow_count} Shadow Shifts.").must_equal true
      #       @rookie_user.shifts << s
      #     else
      #       work_shifts = @rookie_user.shifts
      #       @rookie_user.shift_status_message.include?(
      #           "#{work_shifts.length} of 9 Shifts Selected.  You need to pick #{9 - (work_shifts.length)}").must_equal true
      #
      #       @rookie_user.shifts << s
      #     end
      #   end
      #   # @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
      #   @rookie_user.shift_status_message.include?("All required shifts selected for round 0. (9 of 9)").must_equal true
      #   bFound1 = false
      #   bFound2 = false
      #   # @rookie_user.shift_status_message.each do |m|
      #   #   if m.match(/Need \d* Shadow Shifts./)
      #   #     bFound1 = true
      #   #   end
      #   #   if m.match(/of 5 Round One Rookie Shifts Selected./)
      #   #     bFound2 = true
      #   #   end
      #   # end
      #   bFound1.must_equal false
      #   bFound2.must_equal false
      # end

      # it "should report for round 1 selections" do
      #   config = SysConfig.first
      #   config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
      #   config.save
      #   Shift.all.each do |s|
      #     next if @rookie_user.is_working? s.shift_date
      #     break if @rookie_user.non_meeting_shifts.length >= 5
      #
      #     shadow_count = @rookie_user.shadow_count
      #     if @rookie_user.non_meeting_shifts.length < SHADOW_COUNT
      #       next unless s.shadow?
      #       @rookie_user.shift_status_message.include?("#{shadow_count} of #{SHADOW_COUNT} selected.  Need #{SHADOW_COUNT - shadow_count} Shadow Shifts.").must_equal true
      #       @rookie_user.shifts << s
      #     else
      #       @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
      #
      #       @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length} of 9 Shifts Selected.  You need to pick #{9 - (@rookie_user.shifts.length)}").must_equal true
      #       @rookie_user.shifts << s
      #     end
      #   end
      #   @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
      #   @rookie_user.shift_status_message.include?("All required shifts selected for round 1. (9 of 9)").must_equal true
      # end

      # it "should report if shadow dropped after round 1 selections" do
      #   config = SysConfig.first
      #   config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
      #   config.save
      #   Shift.all.each do |s|
      #
      #     if s.can_select(@rookie_user) == true
      #       @rookie_user.shifts << s
      #     end
      #   end
      #
      #   @rookie_user.shifts.length.must_equal 14
      #
      #   @rookie_user.shifts.each do |s|
      #     if s.shadow?
      #       s.user_id = nil
      #       s.save!
      #       @rookie_user.shifts.reload
      #       break
      #     end
      #   end
      #   @rookie_user.shifts.length.must_equal 13
      #   messages = @rookie_user.shift_status_message
      #   messages.include?("3 of 4 selected.  Need 1 Shadow Shifts.").must_equal true
      #   messages.include?( "Shifts Only Before: #{@rookie_user.first_non_shadow}").must_equal true
      # end
    end
  end


end
