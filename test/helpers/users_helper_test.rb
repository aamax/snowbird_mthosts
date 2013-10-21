require "test_helper"

# user picks shadow and round 1.  drop shadow.  message says pick shadow shifts

class UsersHelperTest < ActionView::TestCase
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
    @g1 = ShiftType.find_by_short_name('G1')
    @g2 = ShiftType.find_by_short_name('G2')
    @g3 = ShiftType.find_by_short_name('G3')
    @g4 = ShiftType.find_by_short_name('G4')
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

    it 'should report need a holiday if one not picked' do
      [@rookie_user, @group1_user, @group2_user, @group3_user].each do |u|
        u.has_holiday_shift?.must_equal false
        u.shift_status_message.include?("NOTE:  A Holiday Shift needs to be selected").must_equal true
      end
    end

    it 'should not report need a holiday if one is picked' do
      [@rookie_user, @group1_user, @group2_user, @group3_user].each do |u|
        HOLIDAYS.each do |h|
          shift = FactoryGirl.create(:shift, shift_date: h, shift_type_id: @g1.id)

          u.shifts << shift
          u.has_holiday_shift?.must_equal true
        end
      end
    end

    describe "rookie" do
      it "should report for prior to bingo shift selections" do
        config = SysConfig.first
        config.bingo_start_date = Date.today + 2.days
        config.save
        Shift.all.each do |s|
          next if @rookie_user.is_working? s.shift_date
          break if @rookie_user.shifts.length >= 7

          shadow_count = @rookie_user.shadow_count
          if @rookie_user.shifts.length < 2
            next unless s.shadow?
            @rookie_user.shift_status_message.include?("#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts.").must_equal true
            @rookie_user.shifts << s
          else
            next unless s.round_one_rookie_shift?
            @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length - 2} of 5 Round One Rookie Shifts Selected.  Need #{5 - (@rookie_user.shifts.length - 2)} Round One Rookie Shifts.").must_equal true
            @rookie_user.shifts << s
          end
        end
        @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round One Rookie Shifts Selected.").must_equal true
        bFound1 = false
        bFound2 = false
        @rookie_user.shift_status_message.each do |m|
          if m.match(/Need \d* Shadow Shifts./)
            bFound1 = true
          end
          if m.match(/of 5 Round One Rookie Shifts Selected./)
            bFound2 = true
          end
        end
        bFound1.must_equal false
        bFound2.must_equal false
      end

      it "should report for round 1 selections" do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
        config.save
        Shift.all.each do |s|
          next if @rookie_user.is_working? s.shift_date
          break if @rookie_user.shifts.length >= 7

          shadow_count = @rookie_user.shadow_count
          if @rookie_user.shifts.length < 2
            next unless s.shadow?
            @rookie_user.shift_status_message.include?("#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts.").must_equal true
            @rookie_user.shifts << s
          else
            next unless s.round_one_rookie_shift?
            @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length - 2} of 5 Round One Rookie Shifts Selected.  Need #{5 - (@rookie_user.shifts.length - 2)} Round One Rookie Shifts.").must_equal true
            @rookie_user.shifts << s
          end
        end
        @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round One Rookie Shifts Selected.").must_equal true
      end

      it "should report for round 2 selections" do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
        config.save
        Shift.all.each do |s|
          next if @rookie_user.is_working? s.shift_date
          break if @rookie_user.shifts.length >= 12
          @rookie_user.shift_status_message.include?("Cannot Pick Shifts Prior to Last Shadow: #{@rookie_user.last_shadow.strftime("%Y-%m-%d")}").must_equal true if @rookie_user.shifts.length >= 2
          @rookie_user.shift_status_message.include?("Cannot Pick Non-Round One Rookie Type Shifts Prior to #{@rookie_user.round_one_end_date.strftime("%Y-%m-%d")}").must_equal true if @rookie_user.shifts.length >= 7
          shadow_count = @rookie_user.shadow_count
          if @rookie_user.shifts.length < 2
            next unless s.shadow?
            @rookie_user.shift_status_message.include?("#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts.").must_equal true
            @rookie_user.shifts << s
          elsif @rookie_user.shifts.length < 7
            next unless s.round_one_rookie_shift?
            @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length - 2} of 5 Round One Rookie Shifts Selected.  Need #{5 - (@rookie_user.shifts.length - 2)} Round One Rookie Shifts.").must_equal true
            @rookie_user.shifts << s
          elsif @rookie_user.shifts.length < 12
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length} of 12 selected.  Need #{12 - @rookie_user.shifts.length} Round 2 Shifts.").must_equal true
            @rookie_user.shifts << s
          else
            @rookie_user.shifts << s
          end
        end
        @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round One Rookie Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round 2 Shifts Selected.").must_equal true
      end

      it "should report if round 1 selection dropped after round 1" do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
        config.save
        Shift.all.each do |s|
          if s.can_select(@rookie_user) == true
            @rookie_user.shifts << s
          end
        end

        @rookie_user.shifts[3].user_id = nil
        @rookie_user.shifts[3].save
        @rookie_user.shifts.delete_at(3)

        @rookie_user.shifts.length.must_equal 11
        messages = @rookie_user.shift_status_message
        messages.include?("All Shadow Shifts Selected.").must_equal true
        messages.include?("4 of 5 Round One Rookie Shifts Selected.  Need 1 Round One Rookie Shifts.").must_equal true
        messages.include?("Cannot Pick Shifts Prior to Last Shadow: #{@rookie_user.shifts[1].shift_date}").must_equal true
        messages.include?("Cannot Pick Shifts After First Non-Round One Shift: #{@rookie_user.first_non_round_one_end_date}").must_equal true
      end

      it "should report if shadow dropped after round 1 selections" do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
        config.save
        Shift.all.each do |s|
          if s.can_select(@rookie_user) == true
            @rookie_user.shifts << s
          end
        end

        @rookie_user.shifts[1].user_id = nil
        @rookie_user.shifts[1].save
        @rookie_user.shifts.delete_at(1)

        @rookie_user.shifts.length.must_equal 11
        messages = @rookie_user.shift_status_message
        messages.include?("1 of 2 selected.  Need 1 Shadow Shifts.").must_equal true
        messages.include?("All Round One Rookie Shifts Selected.").must_equal true
        messages.include?("Cannot Pick Shifts After First Non-Shadow Shift: #{@rookie_user.shifts[1].shift_date}").must_equal true
      end

      it "should report for round 3 selections" do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
        config.save
        Shift.all.each do |s|
          next if @rookie_user.is_working? s.shift_date
          break if @rookie_user.shifts.length >= 16
          @rookie_user.shift_status_message.include?("Cannot Pick Shifts Prior to Last Shadow: #{@rookie_user.last_shadow.strftime("%Y-%m-%d")}").must_equal true if @rookie_user.shifts.length >= 2
          @rookie_user.shift_status_message.include?("Cannot Pick Non-Round One Rookie Type Shifts Prior to #{@rookie_user.round_one_end_date.strftime("%Y-%m-%d")}").must_equal true if @rookie_user.shifts.length >= 7
          shadow_count = @rookie_user.shadow_count
          if @rookie_user.shifts.length < 2
            next unless s.shadow?
            @rookie_user.shift_status_message.include?("#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts.").must_equal true
            @rookie_user.shifts << s
          elsif @rookie_user.shifts.length < 7
            next unless s.round_one_rookie_shift?
            @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length - 2} of 5 Round One Rookie Shifts Selected.  Need #{5 - (@rookie_user.shifts.length - 2)} Round One Rookie Shifts.").must_equal true
            @rookie_user.shifts << s
          elsif @rookie_user.shifts.length < 16
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length} of 16 selected.  Need #{16 - @rookie_user.shifts.length} Round 3 Shifts.").must_equal true
            @rookie_user.shifts << s
          else
            @rookie_user.shifts << s
          end
        end
        @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round One Rookie Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round 3 Shifts Selected.").must_equal true
      end

      it "should report for round 4 selections" do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 4)
        config.save
        Shift.all.each do |s|
          next if @rookie_user.is_working? s.shift_date
          break if @rookie_user.shifts.length >= 16
          @rookie_user.shift_status_message.include?("Cannot Pick Shifts Prior to Last Shadow: #{@rookie_user.last_shadow.strftime("%Y-%m-%d")}").must_equal true if @rookie_user.shifts.length >= 2
          @rookie_user.shift_status_message.include?("Cannot Pick Non-Round One Rookie Type Shifts Prior to #{@rookie_user.round_one_end_date.strftime("%Y-%m-%d")}").must_equal true if @rookie_user.shifts.length >= 7
          shadow_count = @rookie_user.shadow_count
          if @rookie_user.shifts.length < 2
            next unless s.shadow?
            @rookie_user.shift_status_message.include?("#{shadow_count} of 2 selected.  Need #{2 - shadow_count} Shadow Shifts.").must_equal true
            @rookie_user.shifts << s
          elsif @rookie_user.shifts.length < 7
            next unless s.round_one_rookie_shift?
            @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length - 2} of 5 Round One Rookie Shifts Selected.  Need #{5 - (@rookie_user.shifts.length - 2)} Round One Rookie Shifts.").must_equal true
            @rookie_user.shifts << s
          elsif @rookie_user.shifts.length < 16
            @rookie_user.shift_status_message.include?("#{@rookie_user.shifts.length} of 16 selected.  Need #{16 - @rookie_user.shifts.length} Round 4 Shifts.").must_equal true
            @rookie_user.shifts << s
          else
            @rookie_user.shifts << s
          end
        end
        @rookie_user.shift_status_message.include?("All Shadow Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round One Rookie Shifts Selected.").must_equal true
        @rookie_user.shift_status_message.include?("All Round 4 Shifts Selected.").must_equal true
      end
    end

    describe 'non-rookie' do
      it 'not allow picking shifts prior to bingo start' do
        config = SysConfig.first
        config.bingo_start_date = Date.today + 10.days
        config.save
        @group1_user.shift_status_message.include?("No Shifts may be selected before the selection rounds start.").must_equal true
        @group2_user.shift_status_message.include?("No Shifts may be selected before the selection rounds start.").must_equal true
        @group3_user.shift_status_message.include?("No Shifts may be selected before the selection rounds start.").must_equal true
      end

      it 'should report total shift status after round 4 if not complete' do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
        config.save

        @group1_user.shift_status_message.include?("0 of 18 Shifts Selected.  You need to pick 18").must_equal true
        @group2_user.shift_status_message.include?("0 of 18 Shifts Selected.  You need to pick 18").must_equal true
        @group3_user.shift_status_message.include?("0 of 18 Shifts Selected.  You need to pick 18").must_equal true
      end

      it 'should report after round 4 if complete' do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 6)
        config.save
        shifts = Shift.find_all_by_shift_type_id(@p1.id)
        [@group1_user, @group2_user, @group3_user].each do |u|
          shifts.each do |s|
            break if u.shifts.length >= 18
            u.shifts << s
          end
          u.shift_status_message.include?("All required shifts selected. (18 of 18)").must_equal true
        end
      end

      it "should report for round 1 shift selections" do
        config = SysConfig.first
        config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 1)
        config.save
        shifts = Shift.find_all_by_shift_type_id(@p1.id)
        [@group1_user, @group2_user, @group3_user].each do |u|
          shifts.each do |s|
            u.shifts << s
            break if u.shifts.length > 5
            if u.shifts.length < 5
              u.shift_status_message.include?("#{u.shifts.length} of 5 Shifts Selected.  You need to pick #{5 - u.shifts.length}").must_equal true
            else
              u.shift_status_message.include?("All required shifts selected for round 1. (5 of 5)").must_equal true
            end
          end
        end
      end

      it "should report for round 2 shift selections" do
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

      it "should report for round 3 shift selections" do
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

      it "should report for round 4 shift selections" do
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
    end
  end


end
