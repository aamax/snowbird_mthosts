require "test_helper"

class ShiftsHelperTest < ActionView::TestCase

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

  describe "can_select" do
    describe "basic settings" do
      it "should not be selectable if shift user already assigned that day" do
        shift = nil
        Shift.all.each do |s|
          if s.shift_type.short_name[0..1] == 'P1'
            shift = s
            break
          end
        end
        shift.user = @group3_user
        shift.save!
        test_shifts = Shift.where(:shift_date => shift.shift_date)
        test_shifts.each do |ts|
          ts.can_select(@group3_user).must_equal false
        end
      end

      it "should not be selectable if user already assigned" do
        s = Shift.first
        s.user = @group3_user
        s.save
        s.can_select(@group2_user).must_equal false
        s.can_select(@group1_user).must_equal false
        s.can_select(@group2_user).must_equal false
        s.can_select(@group3_user).must_equal false
        s.can_select(@team_leader).must_equal false
        s.can_select(@rookie_user).must_equal false
      end

      describe "team leader shift" do
        it "cannot select tl shift if not team leader" do
          shifts = Shift.where(:shift_type_id => @tl.id)

          shifts.each do |s|
            if s.team_leader?
              s.can_select(@rookie_user).must_equal false
              s.can_select(@group1_user).must_equal false
              s.can_select(@group2_user).must_equal false
              s.can_select(@group3_user).must_equal false
            end
          end
        end
      end

      describe "shadow shift" do
        it "cannot select shadow shift if not rookie" do
          shifts = Shift.where(:shift_type_id => @tl.id)

          shifts.each do |s|
            if s.shadow?
              s.can_select(@team_leader).must_equal false
              s.can_select(@group1_user).must_equal false
              s.can_select(@group2_user).must_equal false
              s.can_select(@group3_user).must_equal false
            end
          end
        end

        it "rookies can select shadow shifts" do
          shifts = Shift.where(:shift_type_id => @sh.id)

          shifts.each do |s|
            s.can_select(@rookie_user).must_equal true
          end
        end
      end
    end

    describe "pre bingo" do
      before  do
        @sys_config.bingo_start_date = Date.today + 1.day
        @sys_config.save!
      end

      describe "rookie" do
        it "can select 2 shadow shifts" do
          dates = []
          shifts = Shift.where(:shift_type_id => @sh.id)
          shifts.all.each do |s|
            next if dates.include? s.shift_date
            break if @rookie_user.shifts.length >= 2
            s.can_select(@rookie_user).must_equal true
            @rookie_user.shifts << s
            dates << s.shift_date
          end
          @rookie_user.shifts.length.must_equal 2
        end

        it "cannot select 3 shadow shifts" do
          shifts = Shift.where(:shift_type_id => @sh.id)
          dates = []
          shifts.all.each do |s|
            break if @rookie_user.shifts.count > 2
            next if dates.include? s.shift_date
            if @rookie_user.shifts.count < 2
              s.can_select(@rookie_user).must_equal true
            else
              s.can_select(@rookie_user).must_equal false
            end
            @rookie_user.shifts << s
            dates << s.shift_date
          end
          @rookie_user.shifts.count == 2
        end

        it "cannot select non-shadow shifts" do
          shifts = Shift.where("shift_type_id <> #{@sh.id}")
          shifts.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end
        end

        describe "after 2 shadows selected" do
          before  do
            @dates = []
            shifts = Shift.where(:shift_type_id => @sh.id)
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              break if @rookie_user.shifts.count >= 2
              if @dates.length > 0
                next if (s.shift_date < (@dates[0] + 2.days))
              end
              @rookie_user.shifts << s
              @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
              @dates << s.shift_date
            end
          end

          it "can select round_one_rookie_shifts after 2 shadow shifts" do
            Shift.all.each do |s|
              next if @dates.include? s.shift_date
              if s.round_one_rookie_shift? && (@max_date < s.shift_date)
                s.can_select(@rookie_user).must_equal true
              end
            end
          end

          it "cannot select shifts before last shadow selection" do
            Shift.all.each do |s|
              next if @dates.include? s.shift_date
              if s.round_one_rookie_shift?
                s.can_select(@rookie_user).must_equal true if s.shift_date > @max_date
                s.can_select(@rookie_user).must_equal false if s.shift_date <= @max_date
              end
            end
          end

          it "can select 5 round_one_rookie_shifts" do
            shifts = Shift.where("shift_date > '#{@max_date}'")
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              break if @rookie_user.shifts.count >= 7
              next if !s.round_one_rookie_shift?
              s.can_select(@rookie_user).must_equal true
              @rookie_user.shifts << s
              @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
              @dates << s.shift_date
            end
          end

          it "cannot select 6 round_one_rookie_shifts" do
            shifts = Shift.where("shift_date > '#{@max_date}'")
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              next if !s.round_one_rookie_shift?
              if @rookie_user.shifts.count < 7
                @rookie_user.shifts << s
                @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
                @dates << s.shift_date
              else
                s.can_select(@rookie_user).must_equal false
              end
            end
          end

          it "cannot select non round_one_rookie shifts" do
            shifts = Shift.where("shift_date > '#{@max_date}'")
            shifts.all.each do |s|
              next if s.round_one_rookie_shift?
              s.can_select(@rookie_user).must_equal false
            end
          end
        end
      end

      describe "non-rookie" do
        it "group 1 cannot select any shifts" do
          Shift.all.each do |s|
            s.can_select(@group1_user).must_equal false
          end
        end

        it "group 2 cannot select any shifts" do
          Shift.all.each do |s|
            s.can_select(@group2_user).must_equal false
          end
        end

        it "group 3 cannot select any shifts" do
          Shift.all.each do |s|
            s.can_select(@group3_user).must_equal false
          end
        end

        it "team leader cannot select any shifts" do
          Shift.all.each do |s|
            next if s.team_leader?
            s.can_select(@team_leader).must_equal false
          end
        end
      end
    end

    describe "round 1" do
      before  do
        @sys_config.bingo_start_date = Date.today
        @sys_config.save!
      end

      describe "rookie" do
        it "can select 2 shadow shifts" do
          dates = []
          shifts = Shift.where(:shift_type_id => @sh.id)
          shifts.all.each do |s|
            next if dates.include? s.shift_date
            break if @rookie_user.shifts.length >= 2
            s.can_select(@rookie_user).must_equal true
            @rookie_user.shifts << s
            dates << s.shift_date
          end
          @rookie_user.shifts.length.must_equal 2
        end

        it "cannot select 3 shadow shifts" do
          shifts = Shift.where(:shift_type_id => @sh.id)
          dates = []
          shifts.all.each do |s|
            break if @rookie_user.shifts.count > 2
            next if dates.include? s.shift_date
            if @rookie_user.shifts.count < 2
              s.can_select(@rookie_user).must_equal true
            else
              s.can_select(@rookie_user).must_equal false
            end
            @rookie_user.shifts << s
            dates << s.shift_date
          end
          @rookie_user.shifts.count == 2
        end

        it "cannot select non-shadow shifts before shadows picked" do
          shifts = Shift.where("shift_type_id <> #{@sh.id}")
          shifts.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end
        end

        describe "after 2 shadows selected" do
          before  do
            @dates = []
            shifts = Shift.where(:shift_type_id => @sh.id)
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              break if @rookie_user.shifts.count >= 2
              if @dates.length > 0
                next if (s.shift_date < (@dates[0] + 2.days))
              end
              @rookie_user.shifts << s
              @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
              @dates << s.shift_date
            end
          end

          it "can select round_one_rookie_shifts" do
            Shift.all.each do |s|
              next if @dates.include? s.shift_date
              if s.round_one_rookie_shift? && (@max_date < s.shift_date)
                s.can_select(@rookie_user).must_equal true
              end
            end
          end

          it "cannot select shifts before last shadow selection" do
            Shift.all.each do |s|
              next if @dates.include? s.shift_date
              if s.round_one_rookie_shift?
                s.can_select(@rookie_user).must_equal true if s.shift_date > @max_date
                s.can_select(@rookie_user).must_equal false if s.shift_date <= @max_date
              end
            end
          end

          it "can select 5 round_one_rookie_shifts" do
            shifts = Shift.where("shift_date > '#{@max_date}'")
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              break if @rookie_user.shifts.count >= 7
              next if !s.round_one_rookie_shift?
              s.can_select(@rookie_user).must_equal true
              @rookie_user.shifts << s
              @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
              @dates << s.shift_date
            end
          end

          it "cannot select 6 round_one_rookie_shifts" do
            shifts = Shift.where("shift_date > '#{@max_date}'")
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              next if !s.round_one_rookie_shift?
              if @rookie_user.shifts.count < 7
                @rookie_user.shifts << s
                @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
                @dates << s.shift_date
              else
                s.can_select(@rookie_user).must_equal false
              end
            end
          end

          it "cannot select non round_one_rookie shifts" do
            shifts = Shift.where("shift_date > '#{@max_date}'")
            shifts.all.each do |s|
              next if s.round_one_rookie_shift?
              s.can_select(@rookie_user).must_equal false
            end
          end
        end
      end

      describe "group 1" do
        it "cannot select shifts until start of my round" do
          for d in 0..3 do
            @sys_config.bingo_start_date = (Date.today - d.days)
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group1_user).must_equal false
            end
          end

          for d in 4..5 do
            @sys_config.bingo_start_date = (Date.today - d.days)
            @sys_config.save!
            Shift.all.each do |s|
              next if s.team_leader? || s.shadow?
              s.can_select(@group1_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          for d in @start_date..(@start_date + 4.days) do
            s = Shift.where("shift_type_id = #{@p1.id} and shift_date = '#{d}'").first
            @group1_user.shifts << s
          end
          @group1_user.shifts.length.must_equal 5
          Shift.all.each do |s|
            s.can_select(@group1_user).must_equal false
          end
        end
      end

      describe "group 2" do
        it "cannot select shifts until start of my round" do
          for d in 0..1 do
            @sys_config.bingo_start_date = (Date.today - d.days)
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group2_user).must_equal false
            end
          end

          for d in 2..5 do
            @sys_config.bingo_start_date = (Date.today - d.days)
            @sys_config.save!
            Shift.all.each do |s|
              next if s.team_leader? || s.shadow?
              s.can_select(@group2_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          for d in @start_date..(@start_date + 4.days) do
            s = Shift.where("shift_type_id = #{@p1.id} and shift_date = '#{d}'").first
            @group2_user.shifts << s
          end
          @group2_user.shifts.length.must_equal 5
          Shift.all.each do |s|
            s.can_select(@group2_user).must_equal false
          end
        end
      end

      describe "group 3"do
        it "cannot select shifts until start of my round" do
          for d in 4..5 do
            @sys_config.bingo_start_date = (Date.today - d.days)
            @sys_config.save!
            Shift.all.each do |s|
              next if s.team_leader? || s.shadow?
              s.can_select(@group3_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          for d in @start_date..(@start_date + 4.days) do
            s = Shift.where("shift_type_id = #{@p1.id} and shift_date = '#{d}'").first
            @group3_user.shifts << s
          end
          @group3_user.shifts.length.must_equal 5
          Shift.all.each do |s|
            s.can_select(@group3_user).must_equal false
          end
        end


      end
    end

    describe "round 2" do
      before  do
        # select 5 shifts for all users (7 for rookies)
        Shift.all.each do |s|
          @sys_config.bingo_start_date = (Date.today -  4.days)
          @sys_config.save!
          if ((s.short_name == 'P1') && (s.can_select(@group1_user) == true))
            @group1_user.shifts << s
            @last_group1_shift = s
          end
          if ((s.can_select(@rookie_user) == true))
            @rookie_user.shifts << s
            @last_rookie_shift = s
          end
          @sys_config.bingo_start_date = (Date.today -  2.days)
          @sys_config.save!
          if ((s.short_name == 'P2') && (s.can_select(@group2_user) == true))
            @group2_user.shifts << s
            @last_group2_shift = s
          end
          @sys_config.bingo_start_date = Date.today
          @sys_config.save!
          if ((s.short_name == 'P3') && (s.can_select(@group3_user) == true))
            @group3_user.shifts << s
            @last_group3_shift = s
          end
        end
      end

      describe "rookie" do
        it "cannot select shifts until start of my round" do
          @rookie_user.shifts.count.must_equal 7
          @rookie_user.shadow_count.must_equal 2
          @rookie_user.round_one_type_count.must_equal 5
          for d in 0..3 do
            @sys_config.bingo_start_date = (Date.today - (d.days + 6.days))
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@rookie_user).must_equal false
            end
          end

          for d in 4..5 do
            @sys_config.bingo_start_date = (Date.today -  (d.days + 6.days))
            @sys_config.save!
            Shift.all.each do |s|
              next if ((s.short_name != 'P4') || s.team_leader? || s.shadow? ||
                  (s.shift_date <= @last_rookie_shift.shift_date))
              s.can_select(@rookie_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          Shift.all.each do |s|
            if s.can_select(@rookie_user)
              @rookie_user.shifts << s
            end
          end
          @rookie_user.shifts.count.must_equal 7
        end
      end

      describe "group 1" do
        it "cannot select shifts until start of my round" do
          @group1_user.shifts.count.must_equal 5

          for d in 0..3 do
            @sys_config.bingo_start_date = (Date.today - (d.days + 6.days))
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group1_user).must_equal false
            end
          end

          for d in 4..5 do
            @sys_config.bingo_start_date = (Date.today -  (d.days + 6.days))
            @sys_config.save!
            Shift.all.each do |s|
              next if ((s.short_name != 'P1') || s.team_leader? || s.shadow? ||
                  (s.shift_date <= @last_group1_shift.shift_date))
              s.can_select(@group1_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          Shift.all.each do |s|
            if s.can_select(@group1_user)
              @group1_user.shifts << s
            end
          end
          @group1_user.shifts.count.must_equal 5
        end
      end

      describe "group 2" do
        it "cannot select shifts until start of my round" do
          @group2_user.shifts.count.must_equal 5

          for d in 0..1 do
            @sys_config.bingo_start_date = (Date.today - (d.days + 6.days))
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group2_user).must_equal false
            end
          end

          for d in 2..5 do
            @sys_config.bingo_start_date = (Date.today -  (d.days + 6.days))
            @sys_config.save!
            Shift.all.each do |s|
              next if ((s.short_name != 'P2') || s.team_leader? || s.shadow? ||
                  (s.shift_date <= @last_group2_shift.shift_date))
              s.can_select(@group2_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          Shift.all.each do |s|
            if s.can_select(@group2_user)
              @group2_user.shifts << s
            end
          end
          @group2_user.shifts.count.must_equal 5
        end
      end

      describe "group 3" do
        it "cannot select shifts until start of my round" do
          @group3_user.shifts.count.must_equal 5

          for d in 0..5 do
            @sys_config.bingo_start_date = (Date.today -  (d.days + 6.days))
            @sys_config.save!
            Shift.all.each do |s|
              next if ((s.short_name != 'P3') || s.team_leader? || s.shadow? ||
                  (s.shift_date <= @last_group3_shift.shift_date))
              s.can_select(@group3_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          Shift.all.each do |s|
            if s.can_select(@group3_user)
              @group3_user.shifts << s
            end
          end
          @group3_user.shifts.count.must_equal 5
        end
      end
    end

    describe "round 3" do
      before  do
        # select 10 shifts for all users (12 for rookies)
        Shift.all.each do |s|
          @sys_config.bingo_start_date = (Date.today -  10.days)
          @sys_config.save!
          if ((s.short_name == 'P1') && (s.can_select(@group1_user) == true))
            @group1_user.shifts << s
            @last_group1_shift = s
          end
          if ((s.can_select(@rookie_user) == true))
            @rookie_user.shifts << s
            @last_rookie_shift = s
          end
          @sys_config.bingo_start_date = (Date.today -  8.days)
          @sys_config.save!
          if ((s.short_name == 'P2') && (s.can_select(@group2_user) == true))
            @group2_user.shifts << s
            @last_group2_shift = s
          end
          @sys_config.bingo_start_date = (Date.today - 6.days)
          @sys_config.save!
          if ((s.short_name == 'P3') && (s.can_select(@group3_user) == true))
            @group3_user.shifts << s
            @last_group3_shift = s
          end
        end
      end

      describe "group 3" do
        it "cannot select shifts until start of my round" do
          @group3_user.shifts.count.must_equal 10

          for d in 0..5 do
            @sys_config.bingo_start_date = (Date.today -  (d.days + 12.days))
            @sys_config.save!
            Shift.all.each do |s|
              next if ((s.short_name != 'P3') || s.team_leader? || s.shadow? ||
                  (s.shift_date <= @last_group3_shift.shift_date))
              s.can_select(@group3_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          Shift.all.each do |s|
            if s.can_select(@group3_user)
              @group3_user.shifts << s
            end
          end
          @group3_user.shifts.count.must_equal 10
        end
      end


      describe "group 2" do
        it "cannot select shifts until start of my round" do
          @group2_user.shifts.count.must_equal 10

          for d in 0..1 do
            @sys_config.bingo_start_date = (Date.today - (d.days + 12.days))
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group2_user).must_equal false
            end
          end

          for d in 2..5 do
            @sys_config.bingo_start_date = (Date.today -  (d.days + 12.days))
            @sys_config.save!
            Shift.all.each do |s|
              next if ((s.short_name != 'P2') || s.team_leader? || s.shadow? ||
                  (s.shift_date <= @last_group2_shift.shift_date))
              s.can_select(@group2_user).must_equal true
            end
          end
        end

        it 'cannot select more than 5 shifts in round' do
          Shift.all.each do |s|
            if s.can_select(@group2_user)
              @group2_user.shifts << s
            end
          end
          @group2_user.shifts.count.must_equal 10
        end
      end

    end


    #describe "round 4" do
    #
    #end

  end


end
