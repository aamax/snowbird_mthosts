require "test_helper"

class ShiftsHelperTest < ActionView::TestCase

  before do
    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @newer_user = User.find_by_name('g3')
    @middle_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g1')
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
    @c3 = ShiftType.find_by_short_name('C3weekend')
    @c4 = ShiftType.find_by_short_name('C4weekend')
    @bg = ShiftType.find_by_short_name('BG')
    @tl = ShiftType.find_by_short_name('TL')

    @start_date = (Date.today()  + 20.days)
  end

  describe 'can_drop' do
    describe 'all hosts' do
      it 'cannot drop shifts within two week limit' do
        # set bingo to start 6 rounds ago
        @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 6)
        @sys_config.save!

        # create shadow and select by rookie (shift date 1 week out)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @sh.id, :user_id => @rookie_user.id)

        # create 3 other shifts and select by other hosts (shift date 1 week out)
        @g1shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p1.id, :user_id => @newer_user.id)
        @g2shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p2.id, :user_id => @middle_user.id)
        @g3shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p3.id, :user_id => @senior_user.id)

        # can not drop any shifts
        @rookieshift.can_drop(@rookie_user).must_equal false
        @g1shift.can_drop(@newer_user).must_equal false
        @g2shift.can_drop(@middle_user).must_equal false
        @g3shift.can_drop(@senior_user).must_equal false
      end
    end

    describe 'non-rookies' do
      it 'can drop any shifts outside of 2 week window' do
        @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 6)
        @sys_config.save!

        # create 3 other shifts and select by other hosts (shift date 1 week out)
        @g1shift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p1.id, :user_id => @newer_user.id)
        @g2shift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p2.id, :user_id => @middle_user.id)
        @g3shift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p3.id, :user_id => @senior_user.id)

        # can not drop any shifts
        @g1shift.can_drop(@newer_user).must_equal true
        @g2shift.can_drop(@middle_user).must_equal true
        @g3shift.can_drop(@senior_user).must_equal true
      end

    end

    describe 'rookies' do
      # it 'cannot drop shadow shifts if any other shifts have been selected' do
      # @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 6)
      # @sys_config.save!
      #
      # # create shadow and select by rookie (shift date 1 week out)
      # @sha1 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks, :shift_type_id => @sh.id, :user_id => @rookie_user.id)
      # @sha2 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 1.day, :shift_type_id => @sh.id, :user_id => @rookie_user.id)
      #
      # @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 2.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
      # @sha1.can_drop(@rookie_user).must_equal false
      # @sha2.can_drop(@rookie_user).must_equal false
      # end
      #
      # it 'cannot drop any round 1 shifts if non round one shift is shift number 8' do
      # @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 6)
      # @sys_config.save!
      #
      # # create shadow and select by rookie (shift date 1 week out)
      # @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks, :shift_type_id => @sh.id, :user_id => @rookie_user.id)
      # @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 1.day, :shift_type_id => @sh.id, :user_id => @rookie_user.id)
      #
      # sh1 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 2.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
      # sh2 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 3.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
      # sh3 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 4.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
      # sh4 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 5.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
      # sh5 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 6.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
      #
      # sh6 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 7.days, :shift_type_id => @p1.id, :user_id => @rookie_user.id)
      # sh1.can_drop(@rookie_user).must_equal false
      # sh2.can_drop(@rookie_user).must_equal false
      # sh3.can_drop(@rookie_user).must_equal false
      # sh4.can_drop(@rookie_user).must_equal false
      # sh5.can_drop(@rookie_user).must_equal false
      # sh6.can_drop(@rookie_user).must_equal true
      # end

      it 'can drop non shadow, non-round one shifts outside of 2 week window' do
        @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 6)
        @sys_config.save!

        # create shadow and select by rookie (shift date 1 week out)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks, :shift_type_id => @sh.id, :user_id => @rookie_user.id)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 1.day, :shift_type_id => @sh.id, :user_id => @rookie_user.id)

        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 2.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 3.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 4.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 5.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 6.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)

        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 7.days, :shift_type_id => @p1.id, :user_id => @rookie_user.id)

        @rookieshift.can_drop(@rookie_user).must_equal true
      end

    end

  end

  describe "can_select" do
    describe "team leaders" do
      before do
        @sys_config.bingo_start_date = Date.today + 1.day
        @sys_config.save!
        Shift.all.each do |s|
          if s.can_select(@team_leader)
            @team_leader.shifts << s if s.short_name == "TL"
            break if @team_leader.shifts.count >= 12
          else
            s.short_name.wont_equal "TL"
          end
        end
      end

      it 'must have 12 shifts after setup' do
        @team_leader.shifts.count.must_equal 12
      end

      it "can select shifts regardless of bingo if shift is open" do
        shifts = Shift.all
        unselected = shifts.delete_if {|s| !s.user_id.nil? }
        @senior_user.shifts << unselected[0]
        target_shift = unselected[0]

        target_shift.can_select(@team_leader).must_equal false
        shifts.each do |s|
          if s.user_id.nil? && !s.shadow? && !@team_leader.is_working?(s.shift_date)
            s.can_select(@team_leader).must_equal true
          else
            s.can_select(@team_leader).must_equal false
          end
        end
      end

      # describe 'round 1' do
      #   before do
      #     @sys_config.bingo_start_date = Date.today - 1.day
      #     @sys_config.save!
      #
      #     HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 1
      #   end
      #
      #   # do not count team lead shifts against quota for round
      #   it 'should allow picking regular shifts in round 1 in spite of team leader shift count' do
      #     shifts = Shift.where(:shift_type_id => @p1.id)
      #     shifts.each do |s|
      #       next if @team_leader.is_working? s.shift_date
      #       s.can_select(@team_leader).must_equal true
      #     end
      #   end
      #
      #   # can only pick up to 5 shifts in round 1
      #   it 'can only pick up to 5 shifts in round 1' do
      #     shifts = Shift.where(:shift_type_id => @p1.id)
      #     shifts.each do |s|
      #       if @team_leader.shifts.count < 17
      #         next if @team_leader.is_working? s.shift_date
      #         s.can_select(@team_leader).must_equal true
      #         @team_leader.shifts << s
      #       else
      #         s.can_select(@team_leader).must_equal false
      #       end
      #     end
      #   end
      #
      #   it "cannot pick more than 18 team leader shifts prior to end of bingo" do
      #     shifts = Shift.where(:shift_type_id => @tl.id)
      #     shifts.each do |s|
      #       next unless s.user_id.nil?
      #
      #       if @team_leader.shifts.count < 18
      #         s.can_select(@team_leader).must_equal true
      #         @team_leader.shifts << s
      #       else
      #         s.can_select(@team_leader).must_equal false
      #       end
      #     end
      #   end
      # end
      #
      # describe 'round 2' do
      #   before do
      #     @sys_config.bingo_start_date = Date.today - 3.days
      #     @sys_config.save!
      #
      #     HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 2
      #   end
      #
      #   it 'cannot select more than 18 shifts before bingo is done' do
      #     shifts = Shift.where(:shift_type_id => @p1.id)
      #     shifts.each do |s|
      #       next unless s.user_id.nil?
      #       next if @team_leader.is_working? s.shift_date
      #
      #       if @team_leader.shifts.count < 18
      #         s.can_select(@team_leader).must_equal true
      #         @team_leader.shifts << s
      #       else
      #         s.can_select(@team_leader).must_equal false
      #       end
      #     end
      #   end
      # end

      describe 'after bingo' do
        before do
          @sys_config.bingo_start_date = Date.today - (3 * 4).days
          @sys_config.save!

          (HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader) >= 5).must_equal true
        end

        it 'can select more than 18 shifts' do
          shifts = Shift.where(:shift_type_id => @p1.id)
          shifts.each do |s|
            next unless s.user_id.nil?
            next if @team_leader.is_working? s.shift_date
            s.can_select(@team_leader).must_equal true
            @team_leader.shifts << s
          end
        end
      end
    end

    describe "basic settings" do
      it "should not be selectable if shift user already assigned that day" do
        shift = nil
        Shift.all.each do |s|
          if s.shift_type.short_name[0..1] == 'P1'
            shift = s
            break
          end
        end
        @senior_user.shifts << shift
        test_shifts = Shift.where(:shift_date => shift.shift_date)
        test_shifts.each do |ts|
          ts.can_select(@senior_user).must_equal false
        end
      end

      it "should not be selectable if user already assigned" do
        s = Shift.first
        s.user = @senior_user
        s.save
        s.can_select(@middle_user).must_equal false
        s.can_select(@newer_user).must_equal false
        s.can_select(@middle_user).must_equal false
        s.can_select(@senior_user).must_equal false
        s.can_select(@team_leader).must_equal false
        s.can_select(@rookie_user).must_equal false
      end

      describe "team leader shift" do
        it "cannot select tl shift if not team leader" do
          @p2weekday = FactoryGirl.create(:shift_type, :short_name => 'P2weekday')
          curr_date = @sys_config.season_start_date
          (0..10).each do |n|
            FactoryGirl.create(:shift, :shift_type_id => @p2weekday.id, :shift_date => curr_date)
            curr_date += 1.day
          end

          shifts = Shift.where(:shift_type_id => @tl.id)
          others = Shift.where(:shift_type_id => @p2weekday)
          shifts = (shifts + others)
          shifts.each do |s|
            [@rookie_user, @newer_user, @middle_user, @senior_user ].each do |u|
              s.can_select(u).must_equal false
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
              s.can_select(@newer_user).must_equal false
              s.can_select(@middle_user).must_equal false
              s.can_select(@senior_user).must_equal false
            end
          end
        end

        describe "rookies" do
          it "can select shadow shifts" do
            shifts = Shift.where(:shift_type_id => @sh.id)
            shifts.each do |s|
              s.can_select(@rookie_user).must_equal true
            end
          end

          describe "user has all shadows and round 1 types picked" do
            before do
              shifts = Shift.where(:shift_type_id => @sh.id)
              dt = shifts[0].shift_date + 3.days

              shifts.each do |s|
                next if dt != s.shift_date
                dt = s.shift_date + 3.days
                if s.can_select(@rookie_user) == true
                  @rookie_user.shifts << s
                  @last_shadow = s.shift_date
                end
                break if @rookie_user.shifts.length == 2
              end

              # select 5 round 1 shifts - spaced out
              shifts = Shift.where("shift_type_id in (#{@g1.id}, #{@g2.id})")
              dt = shifts[0].shift_date + 3.days

              shifts.each do |s|
                next if dt != s.shift_date
                dt = s.shift_date + 3.days
                if s.can_select(@rookie_user) == true
                  if @rookie_user.shifts.length == 2
                    @first_round1 = s.shift_date
                  end
                  @rookie_user.shifts << s
                  @last_round1 = s.shift_date
                end
                break if @rookie_user.shifts.length == 7
              end
            end

            it "can only select shadows prior to first round 1 shift" do
              @rookie_user.shifts[1].user_id = nil
              @rookie_user.shifts[1].save
              @rookie_user.shifts.delete_at(1)

              Shift.all.each do |s|
                if s.round_one_rookie_shift?
                  s.can_select(@rookie_user).must_equal false
                elsif s.shadow? && (!@rookie_user.is_working?(s.shift_date)) && (s.shift_date < @first_round1)
                  s.can_select(@rookie_user).must_equal true
                else
                  s.can_select(@rookie_user).must_equal false
                end
              end
            end

            it "can only select round 1s prior to non-round 1 (after picking a non round 1)" do
              @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
              @sys_config.save!
              dt = @rookie_user.shifts[-1].shift_date

              # set a non round 1 shift
              shift = Shift.where("shift_date >= '#{dt + 3.days}' and shift_type_id = #{@p1.id}")
              @rookie_user.shifts << shift.first

              # remove a round one shift
              @rookie_user.shifts[3].user_id = nil
              @rookie_user.shifts[3].save
              @rookie_user.shifts.delete_at(3)

              Shift.all.each do |s|
                if ((@rookie_user.is_working?(s.shift_date)) || (s.shift_date < @rookie_user.last_shadow) ||
                    (!s.round_one_rookie_shift?) || (s.shift_date >= @rookie_user.first_non_round_one_end_date))
                  s.can_select(@rookie_user).must_equal(false)
                else
                  s.can_select(@rookie_user).must_equal true
                end
              end
            end
          end

            describe "round one shift selections" do
              before do
                shifts = Shift.where(:shift_type_id => @sh.id)
                shifts.each do |s|
                  if s.can_select(@rookie_user) == true
                    @rookie_user.shifts << s
                    @new_shift_date = s.shift_date + 1.day
                    @last_shadow = s.shift_date
                  end
                  break if @rookie_user.shifts.length == 2
                end

                # add shifts for G3 and G4 fridays
                @g3f = FactoryGirl.create(:shift_type, short_name: 'G3friday')
                @g4f = FactoryGirl.create(:shift_type, short_name: 'G4friday')

                (1..30).each do
                  FactoryGirl.create(:shift, shift_type_id: @g3f.id, shift_date: @new_shift_date)
                  FactoryGirl.create(:shift, shift_type_id: @g4f.id, shift_date: @new_shift_date)
                  @new_shift_date += 1.day
                end
              end

              it "can't select G3 or G4 friday shifts" do
                Shift.all.each do |s|
                  break if @rookie_user.shifts.length >= 7
                  if ((s.short_name == 'G3friday') || (s.short_name == 'G4friday'))
                    test_val = s.can_select(@rookie_user)
                    test_val.must_equal(false)
                  end
                end
              end

              it "can select G1,G2,G3,G4,C3,C4 on Sat and Sun and holidays" do
                test_array = ['G1','G2','G3','G4']
                Shift.all.each do |s|
                  break if @rookie_user.shifts.length >= 7
                  next unless test_array.include? s.short_name[0..1]
                  next if s.shift_date <= @last_shadow
                  test_val = s.can_select(@rookie_user)
                  test_name = s.full_short_name.downcase
                  if ((test_name == 'g3friday') || (test_name == 'g4friday'))
                    test_val.must_equal(false)
                  else
                    test_val.must_equal(true)
                  end
                end
              end

            end
        end
      end
    end

    describe "pre bingo" do
      before  do
        @sys_config.bingo_start_date = Date.today + 1.day
        @sys_config.save!

        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 0
      end

      describe "rookie" do
        it "can select only 2 shadow shifts" do
          dates = []
          shifts = Shift.where(:shift_type_id => @sh.id)
          shifts.all.each do |s|
            next if dates.include? s.shift_date
            next if !s.shadow?
            status = s.can_select(@rookie_user)
            if @rookie_user.shifts.count < 2
              status.must_equal true
              @rookie_user.shifts << s
              dates << s.shift_date
            else
              status.must_equal false
            end
          end
          @rookie_user.shifts.length.must_equal 2
        end

        it "cannot select non-shadow shifts" do
          shifts = Shift.where("shift_type_id <> #{@sh.id}")
          shifts.each do |s|
            s.can_select(@rookie_user).must_equal false
          end
        end

        describe "after 2 shadows selected" do
          before  do
            @dates = []
            icnt = 0
            shifts = Shift.where(:shift_type_id => @sh.id)
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              break if @rookie_user.shifts.count >= 2
              icnt += 1
              next if icnt < 3
              next if (s.shift_date < (@dates[0] + 2.days)) if (@dates.length > 0)

              @rookie_user.shifts << s
              @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
              @dates << s.shift_date
            end
          end

          it "can select round_one_rookie_shifts after 2 shadow shifts" do
            Shift.all.each do |s|
              next if @dates.include? s.shift_date
              stat = s.can_select(@rookie_user)
              if s.round_one_rookie_shift? && (@max_date < s.shift_date)
                stat.must_equal true
              else
                stat.must_equal false
              end
            end
          end

          it "cannot select shifts before last shadow selection" do
            Shift.all.each do |s|
              next if @dates.include? s.shift_date

              if s.round_one_rookie_shift?
                stat = s.can_select(@rookie_user)
                stat.must_equal true if s.shift_date > @max_date
                stat.must_equal false if s.shift_date <= @max_date
              end
            end
          end

          it "can select 5 round_one_rookie_shifts" do
            shifts = Shift.where("shift_date > '#{@max_date}'")
            shifts.all.each do |s|
              next if @dates.include? s.shift_date
              next if !s.round_one_rookie_shift?
              stat = s.can_select(@rookie_user)
              if @rookie_user.shifts.count < 7
                stat.must_equal true
                @rookie_user.shifts << s
                @max_date = s.shift_date if (@max_date.nil? || (@max_date < s.shift_date))
                @dates << s.shift_date
              else
                stat.must_equal false
              end
            end
            @rookie_user.shifts.length.must_equal 7
          end

          it "cannot select non round_one_rookie shifts" do
            shifts = Shift.all
            shifts.each do |s|
              next if s.round_one_rookie_shift?
              s.can_select(@rookie_user).must_equal false
            end
          end

          it 'only 3 rookies per day on weekend shifts' do
            r1 = FactoryGirl.create(:user, :email => 'f1.user@example.com', :start_year => @sys_config.season_year, :active_user => true)
            r2 = FactoryGirl.create(:user, :email => 'f2.user@example.com', :start_year => @sys_config.season_year, :active_user => true)
            r3 = FactoryGirl.create(:user, :email => 'f3.user@example.com', :start_year => @sys_config.season_year, :active_user => true)
            shifts = Shift.where(:shift_type_id => @sh.id)
            shifts.all.each do |s|
              if s.can_select(r1) == true
                r1.shifts << s if r1.shifts.count < 2
              end

              if s.can_select(r2) == true
                r2.shifts << s if r2.shifts.count < 2
              end

              if s.can_select(r3) == true
                r3.shifts << s if r3.shifts.count < 2
              end
            end
            shift_date = @rookie_user.last_shadow
            shift_date = r1.last_shadow if r1.last_shadow > shift_date
            shift_date = r2.last_shadow if r2.last_shadow > shift_date
            shift_date = r3.last_shadow if r3.last_shadow > shift_date
            shift_date += 5.days

            shift_types = [@g1.id, @g2.id, @g3.id, @g4.id, @c3.id, @c4.id]
            shifts = Shift.where("shift_type_id in (#{shift_types.join(',')}) and shift_date = '#{shift_date}'")
            r1.shifts << shifts[0]
            r2.shifts << shifts[1]
            r3.shifts << shifts[2]

            shifts[3].can_select(@rookie_user).must_equal false
          end

          it 'only 1 rookies per day on friday shifts' do
            g1friday = FactoryGirl.create(:shift_type, short_name: 'G3friday')
            r1 = FactoryGirl.create(:user, :email => 'f1.user@example.com', :start_year => @sys_config.season_year)
            dt = Date.today() + 20.days
            (0..1).each do |n|
              FactoryGirl.create(:shift, :shift_type_id => g1friday.id, :shift_date => dt)
            end
            shifts = Shift.where("shift_type_id = #{g1friday.id} and shift_date = '#{dt}'")
            r1.shifts << shifts[0]
            shifts[1].can_select(@rookie_user).must_equal false
          end
        end
      end

      describe "non-rookie" do
        it "non-rookies cannot select any shifts" do
          Shift.all.each do |s|
            s.can_select(@newer_user).must_equal false
            s.can_select(@middle_user).must_equal false
            s.can_select(@senior_user).must_equal false
          end
        end
      end
    end

    describe "round 1" do
      describe "senior" do
        it "cannot select shifts until start of my round" do
          @sys_config.bingo_start_date = (Date.today + 1.day)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@senior_user).must_equal false
          end
          @sys_config.bingo_start_date = Date.today
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?)
            s.can_select(@senior_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = Date.today
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@senior_user)
              @senior_user.shifts << s
            end
          end
          @senior_user.shifts.count.must_equal 5
        end
      end

      describe "middle" do
        it "cannot select shifts until start of my round" do
          @sys_config.bingo_start_date = (Date.today)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@middle_user).must_equal false
          end

          @sys_config.bingo_start_date = (Date.today -  1.day)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@middle_user.shifts.include?(s))
            s.can_select(@middle_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = (Date.today -  1.days)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@middle_user)
              @middle_user.shifts << s
            end
          end
          @middle_user.shifts.count.must_equal 5
        end
      end

      describe "newer" do
        it "cannot select shifts until start of my round" do
          @sys_config.bingo_start_date = Date.today - 1.days
          @sys_config.save!

          Shift.all.each do |s|
            s.can_select(@newer_user).must_equal false
          end

          @sys_config.bingo_start_date = (Date.today -  2.days)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@newer_user.shifts.include?(s))
            s.can_select(@newer_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = (Date.today -  2.days)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@newer_user)
              @newer_user.shifts << s
            end
          end
          @newer_user.shifts.count.must_equal 5
        end
      end

      describe "rookie" do
        before  do
          @sys_config.bingo_start_date = (Date.today -  3.days)
          @sys_config.save!
          Shift.all.each do |s|
            if (s.can_select(@rookie_user) == true)
              @rookie_user.shifts << s
              @last_rookie_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @rookie_user.shifts.count.must_equal 7
          @rookie_user.shadow_count.must_equal 2
          assert_operator(@rookie_user.round_one_type_count, :>=, 5, "Not enough round one selections")
          @sys_config.bingo_start_date = (Date.today - 3.days)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end

          @sys_config.bingo_start_date = (Date.today -  4.days)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@rookie_user.shifts.include?(s))
            s.can_select(@rookie_user).must_equal true
          end
        end

        it 'cannot select more than 7 shifts in round' do
          @sys_config.bingo_start_date = (Date.today -  4.days)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@rookie_user)
              @rookie_user.shifts << s
            end
          end
          @rookie_user.shifts.count.must_equal 7
        end
      end
    end

    describe "round 2" do
      describe "senior" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P3') && (s.can_select(@senior_user) == true))
              @senior_user.shifts << s
              @last_senior_shift = s
            end
          end

          HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 1
        end

        it "cannot select shifts until start of my round" do
          @senior_user.shifts.count.must_equal 5
          @sys_config.bingo_start_date = (Date.today -  2.days)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@senior_user).must_equal false
          end
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@senior_user.shifts.include?(s))
            s.can_select(@senior_user).must_equal true
          end
          HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 2
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@senior_user)
              @senior_user.shifts << s
            end
          end
          @senior_user.shifts.count.must_equal 10
        end
      end

      describe "middle" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 1)
          @sys_config.save!
          HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @middle_user).must_equal 1
          Shift.all.each do |s|
            if ((s.short_name == 'P2') && (s.can_select(@middle_user) == true))
              @middle_user.shifts << s
              @last_middle_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @middle_user.shifts.count.must_equal 5
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@middle_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@middle_user.shifts.include?(s))
            s.can_select(@middle_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 2)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@middle_user)
              @middle_user.shifts << s
            end
          end
          @middle_user.shifts.count.must_equal 10
        end
      end

      describe "newer" do
        before  do
          Shift.all.each do |s|
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 1)
            @sys_config.save!
            if ((s.short_name == 'P1') && (s.can_select(@newer_user) == true))
              @newer_user.shifts << s
              @last_group1_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @newer_user.shifts.count.must_equal 5
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@newer_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@newer_user.shifts.include?(s))
            s.can_select(@newer_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 2)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@newer_user)
              @newer_user.shifts << s
            end
          end
          @newer_user.shifts.count.must_equal 10
        end
      end

      describe "rookie" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
          @sys_config.save!
          iCnt = 0
          Shift.all.each do |s|

            if ((s.can_select(@rookie_user) == true))
              iCnt += 1
              next if iCnt < 5

              @rookie_user.shifts << s
              @last_rookie_shift = s

              iCnt = 0
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @rookie_user.shifts.count.must_equal 7
          @rookie_user.shadow_count.must_equal 2
          assert_operator(@rookie_user.round_one_type_count, :>=, 5, "Not enough round one selections")
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || @rookie_user.is_working?(s.shift_date))
            next if (s.shift_date < @rookie_user.round_one_end_date) && !s.round_one_rookie_shift?
            next if (s.shift_date <= @rookie_user.last_shadow)
            s.can_select(@rookie_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@rookie_user)
              @rookie_user.shifts << s
            end
          end
          @rookie_user.shifts.count.must_equal 12
        end

        it "cannot select any non-round1 type shifts prior to 5 round one selections" do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
          @sys_config.save!

          Shift.all.each do |s|
            next if s.shift_date > @rookie_user.round_one_end_date
            next if @rookie_user.is_working? s.shift_date
            next if s.round_one_rookie_shift?
            s.can_select(@rookie_user).must_equal false
          end
        end
      end
    end

    describe "round 3" do
      describe "senior" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P3') && (s.can_select(@senior_user) == true))
              @senior_user.shifts << s
              @last_senior_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @senior_user.shifts.count.must_equal 10
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@senior_user).must_equal false
          end
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@senior_user.shifts.include?(s))
            s.can_select(@senior_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@senior_user)
              @senior_user.shifts << s
            end
          end
          @senior_user.shifts.count.must_equal 15
        end
      end

      describe "middle" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P2') && (s.can_select(@middle_user) == true))
              @middle_user.shifts << s
              @last_middle_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @middle_user.shifts.count.must_equal 10
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@middle_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@middle_user.shifts.include?(s))
            s.can_select(@middle_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 3)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@middle_user)
              @middle_user.shifts << s
            end
          end
          @middle_user.shifts.count.must_equal 15
        end
      end

      describe "rookie" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.can_select(@rookie_user) == true))
              @rookie_user.shifts << s
              @last_rookie_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @rookie_user.shifts.count.must_equal 12
          @rookie_user.shadow_count.must_equal 2
          assert_operator(@rookie_user.round_one_type_count, :>=, 5, "Not enough round one selections")
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@rookie_user.shifts.include?(s))
            s.can_select(@rookie_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@rookie_user)
              @rookie_user.shifts << s
            end
          end
          @rookie_user.shifts.count.must_equal 16
        end
      end

      describe "newer" do
        before  do
          Shift.all.each do |s|
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 2)
            @sys_config.save!
            if ((s.short_name == 'P1') && (s.can_select(@newer_user) == true))
              @newer_user.shifts << s
              @last_newer_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @newer_user.shifts.count.must_equal 10
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@newer_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@newer_user.shifts.include?(s))
            s.can_select(@newer_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 3)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@newer_user)
              @newer_user.shifts << s
            end
          end
          @newer_user.shifts.count.must_equal 15
        end
      end
    end

    describe "round 4 - open round to fill out schedules" do
      describe "senior" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P3') && (s.can_select(@senior_user) == true))
              @senior_user.shifts << s
              @last_senior_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @senior_user.shifts.count.must_equal 15
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@senior_user).must_equal false
          end
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 4)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@senior_user.shifts.include?(s))
            s.can_select(@senior_user).must_equal true
          end
        end

        it 'cannot select more than 3 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 4)
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@senior_user)
              @senior_user.shifts << s
            end
          end
          @senior_user.shifts.count.must_equal 18
        end
      end

      describe "middle" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P2') && (s.can_select(@middle_user) == true))
              @middle_user.shifts << s
              @last_middle_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @middle_user.shifts.count.must_equal 15
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@middle_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@middle_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 4)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@senior_user.shifts.include?(s))


            puts "test shift is true" if  s.can_select(@middle_user) == true

            s.can_select(@middle_user).must_equal true
          end
        end

        it 'cannot select more than 3 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 4)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@middle_user)
              @middle_user.shifts << s
            end
          end
          @middle_user.shifts.count.must_equal 18
        end
      end

      describe "newer" do
        before  do
          Shift.all.each do |s|
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@newer_user, 3)
            @sys_config.save!
            if ((s.short_name == 'P1') && (s.can_select(@newer_user) == true))
              @newer_user.shifts << s
              @last_newer_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @newer_user.shifts.count.must_equal 15
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@newer_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 4)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@newer_user.shifts.include?(s))
            s.can_select(@newer_user).must_equal true
          end
        end

        it 'cannot select more than 3 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 4)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@newer_user)
              @newer_user.shifts << s
            end
          end
          @newer_user.shifts.count.must_equal 18
        end
      end

      describe "rookie" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.can_select(@rookie_user) == true))
              @rookie_user.shifts << s
              @last_rookie_shift = s
            end
          end
        end

        it "cannot select shifts - all filled" do
          @rookie_user.shifts.count.must_equal 16
          @rookie_user.shadow_count.must_equal 2
          assert_operator(@rookie_user.round_one_type_count, :>=, 5, "Not enough round one selections")
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 4)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end
        end
      end

        describe 'after round 4' do
          before do
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 4)
            @sys_config.save!
          end

          describe 'rookie' do
            before do
              # select all round 1 - 4 shifts
              Shift.all.each do |s|
                if s.can_select(@rookie_user)
                  @rookie_user.shifts << s
                end
              end
            end
            it' should not allow selecting shadow shifts' do
              @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
              @sys_config.save!
              @rookie_user.shifts.count.must_equal 16
              Shift.all.each do |s|
                s.can_select(@rookie_user).must_equal false if s.shadow?
              end
            end

            it 'should not allow shifts prior to last shadow' do
              @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
              @sys_config.save!
              last_shadow = @rookie_user.last_shadow
              refute_equal(last_shadow, nil, "last shadow should not be nil")
              Shift.all.each do |s|
                s.can_select(@rookie_user).must_equal false if s.shift_date <= last_shadow
              end
            end

            it 'should not allow non-round1 shifts prior to 5th round1 shift' do
              @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
              @sys_config.save!
              last_round1 = @rookie_user.round_one_end_date
              last_shadow = @rookie_user.last_shadow
              refute_equal(last_shadow, nil, "last shadow should not be nil")
              refute_equal(last_round1, nil, "round 1 date should not be nil")

              Shift.all.each do |s|
                next if !s.user_id.nil?
                next if @rookie_user.is_working?(s.shift_date)
                next if s.shift_date <= last_shadow
                next if (s.short_name == 'TL') || (s.short_name == 'SH')
                if s.shift_date <= last_round1
                  if s.round_one_rookie_shift?
                    s.can_select(@rookie_user).must_equal true if s.shift_date > last_shadow
                    s.can_select(@rookie_user).must_equal false if s.shift_date <= last_shadow
                  end
                else
                  s.can_select(@rookie_user).must_equal true
                end
              end
            end

            it 'should allow unlimited shifts after 5th round1 shift' do
              @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5)
              @sys_config.save!
              last_round1 = @rookie_user.round_one_end_date
              last_shadow = @rookie_user.last_shadow
              refute_equal(last_shadow, nil, "last shadow should not be nil")
              refute_equal(last_round1, nil, "round 1 date should not be nil")

              Shift.all.each do |s|
                next if !s.user_id.nil?
                next if @rookie_user.is_working?(s.shift_date)
                next if s.shift_date <= last_shadow
                next if s.short_name == 'TL' || (s.short_name == 'SH')
                if s.shift_date <= last_round1
                  if s.round_one_rookie_shift?
                    s.can_select(@rookie_user).must_equal true
                    @rookie_user.shifts << s
                  end
                else
                  s.can_select(@rookie_user).must_equal true
                  @rookie_user.shifts << s
                end
              end
            end
          end

          describe 'non-rookie' do
            it "newer" do
              Shift.all.each do |s|
                next s.short_name == 'SH' || s.short_name == 'TL'
                s.can_select(@newer_user).must_equal true
                @newer_user.shifts << s
              end
            end

            it 'middle' do
              Shift.all.each do |s|
                next s.short_name == 'SH' || s.short_name == 'TL'
                s.can_select(@middle_user).must_equal true
                @middle_user.shifts << s
              end
            end

            it 'senior' do
              Shift.all.each do |s|
                next s.short_name == 'SH' || s.short_name == 'TL'
                s.can_select(@senior_user).must_equal true
                @senior_user.shifts << s
              end

            end
          end
        end
    end

  end
end
