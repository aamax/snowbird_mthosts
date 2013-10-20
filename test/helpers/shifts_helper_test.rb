require "test_helper"

def display_user_and_shift(user, shift)
  puts "----- User and shift info --------"
  puts "Bingo Start: #{SysConfig.first.bingo_start_date}"
  puts "Seniority: #{user.seniority}   seniority_group: #{user.seniority_group}"
  puts "Current Round: #{HostUtility.get_current_round(SysConfig.first.bingo_start_date, Date.today, user)}"
  (1..5).each do |num|
    puts "    date for round: #{num}  -  #{HostUtility.date_for_round(user, num)}"
  end


  puts "user: rookie: #{user.rookie?}  g1: #{user.group_1?} g2: #{user.group_2?}  g3: #{user.group_3?}"

  puts "shadow cnt: #{user.shadow_count} last shadow: #{user.last_shadow} "
  puts "rnd1 cnt: #{user.round_one_type_count}  rnd1 first: #{user.first_round_one_end_date}  rnd1 end: #{user.round_one_end_date}"
  puts "first non round 1: #{user.first_non_round_one_end_date} is working: #{user.is_working?(shift.shift_date)}"
  puts ""

  puts "current shift: #{shift.shift_date}  short_name: #{shift.short_name} can select: #{shift.can_select(user)}"
  puts ""

  user.shifts.each do |s|
    puts "dt: #{s.shift_date}  shortname: #{s.short_name}"
  end
  puts "=================================="
end

class ShiftsHelperTest < ActionView::TestCase

  before do
    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g3')
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

  describe 'can_drop' do
    describe 'all hosts' do
      it 'cannot drop shifts within two week limit' do
        # set bingo to start 6 rounds ago
        @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 6)
        @sys_config.save!

        # create shadow and select by rookie (shift date 1 week out)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @sh.id, :user_id => @rookie_user.id)

        # create 3 other shifts and select by other hosts (shift date 1 week out)
        @g1shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p1.id, :user_id => @group1_user.id)
        @g2shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p2.id, :user_id => @group2_user.id)
        @g3shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p3.id, :user_id => @group3_user.id)

        # can not drop any shifts
        @rookieshift.can_drop(@rookie_user).must_equal false
        @g1shift.can_drop(@group1_user).must_equal false
        @g2shift.can_drop(@group2_user).must_equal false
        @g3shift.can_drop(@group3_user).must_equal false
      end
    end

    describe 'non-rookies' do
      it 'can drop any shifts outside of 2 week window' do
        @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 6)
        @sys_config.save!

        # create 3 other shifts and select by other hosts (shift date 1 week out)
        @g1shift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p1.id, :user_id => @group1_user.id)
        @g2shift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p2.id, :user_id => @group2_user.id)
        @g3shift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p3.id, :user_id => @group3_user.id)

        # can not drop any shifts
        @g1shift.can_drop(@group1_user).must_equal true
        @g2shift.can_drop(@group2_user).must_equal true
        @g3shift.can_drop(@group3_user).must_equal true
      end

    end

    describe 'rookies' do
      it 'cannot drop shadow shifts if any other shifts have been selected' do
        @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 6)
        @sys_config.save!

        # create shadow and select by rookie (shift date 1 week out)
        @sha1 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks, :shift_type_id => @sh.id, :user_id => @rookie_user.id)
        @sha2 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 1.day, :shift_type_id => @sh.id, :user_id => @rookie_user.id)

        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 2.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        @sha1.can_drop(@rookie_user).must_equal false
        @sha2.can_drop(@rookie_user).must_equal false
      end

      it 'cannot drop any round 1 shifts if non round one shift is shift number 8' do
        @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 6)
        @sys_config.save!

        # create shadow and select by rookie (shift date 1 week out)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks, :shift_type_id => @sh.id, :user_id => @rookie_user.id)
        @rookieshift = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 1.day, :shift_type_id => @sh.id, :user_id => @rookie_user.id)

        sh1 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 2.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        sh2 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 3.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        sh3 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 4.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        sh4 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 5.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)
        sh5 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 6.days, :shift_type_id => @g1.id, :user_id => @rookie_user.id)

        sh6 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.weeks + 7.days, :shift_type_id => @p1.id, :user_id => @rookie_user.id)
        sh1.can_drop(@rookie_user).must_equal false
        sh2.can_drop(@rookie_user).must_equal false
        sh3.can_drop(@rookie_user).must_equal false
        sh4.can_drop(@rookie_user).must_equal false
        sh5.can_drop(@rookie_user).must_equal false
        sh6.can_drop(@rookie_user).must_equal true
      end

      it 'can drop non shadow, non-round one shifts outside of 2 week window' do
        @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 6)
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
    describe "basic settings" do
      it "should not be selectable if shift user already assigned that day" do
        shift = nil
        Shift.all.each do |s|
          if s.shift_type.short_name[0..1] == 'P1'
            shift = s
            break
          end
        end
        @group3_user.shifts << shift
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
            [@rookie_user, @group1_user, @group2_user, @group3_user ].each do |u|
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
              s.can_select(@group1_user).must_equal false
              s.can_select(@group2_user).must_equal false
              s.can_select(@group3_user).must_equal false
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
              @sys_config.bingo_start_date = HostUtility.date_for_round(@rookie_user, 3)
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
                test_array = ['G1','G2','G3','G4','C3','C4']
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
        end
      end

      describe "non-rookie" do
        it "non-rookies cannot select any shifts" do
          Shift.all.each do |s|
            s.can_select(@group1_user).must_equal false
            s.can_select(@group2_user).must_equal false
            s.can_select(@group3_user).must_equal false
          end
        end
      end
    end

    describe "round 1" do
      describe "group 3" do
        it "cannot select shifts until start of my round" do
          @sys_config.bingo_start_date = (Date.today + 1.day)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@group3_user).must_equal false
          end
          @sys_config.bingo_start_date = Date.today
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?)
            s.can_select(@group3_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = Date.today
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@group3_user)
              @group3_user.shifts << s
            end
          end
          @group3_user.shifts.count.must_equal 5
        end
      end

      describe "group 2" do
        it "cannot select shifts until start of my round" do
          @sys_config.bingo_start_date = (Date.today - 1.days)
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@group2_user) == true
              display_user_and_shift(@group2_user, s)
            end
            s.can_select(@group2_user).must_equal false
          end

          @sys_config.bingo_start_date = (Date.today -  2.days)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@group2_user.shifts.include?(s))
            s.can_select(@group2_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = (Date.today -  2.days)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@group2_user)
              @group2_user.shifts << s
            end
          end
          @group2_user.shifts.count.must_equal 5
        end
      end

      describe "group 1" do
        it "cannot select shifts until start of my round" do
          @sys_config.bingo_start_date = Date.today - 3.days
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@group1_user) == true
              display_user_and_shift(@group1_user, s)
            end
            s.can_select(@group1_user).must_equal false
          end

          @sys_config.bingo_start_date = (Date.today -  4.days)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@group1_user.shifts.include?(s))
            s.can_select(@group1_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = (Date.today -  4.days)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@group1_user)
              @group1_user.shifts << s
            end
          end
          @group1_user.shifts.count.must_equal 5
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
      describe "group 3" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P3') && (s.can_select(@group3_user) == true))
              @group3_user.shifts << s
              @last_group3_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @group3_user.shifts.count.must_equal 5
          @sys_config.bingo_start_date = (Date.today -  6.days)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@group3_user).must_equal false
          end
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@group3_user.shifts.include?(s))
            s.can_select(@group3_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@group3_user)
              @group3_user.shifts << s
            end
          end
          @group3_user.shifts.count.must_equal 10
        end
      end

      describe "group 2" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P2') && (s.can_select(@group2_user) == true))
              @group2_user.shifts << s
              @last_group2_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @group2_user.shifts.count.must_equal 5
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@group2_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@group2_user.shifts.include?(s))
            s.can_select(@group2_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 2)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@group2_user)
              @group2_user.shifts << s
            end
          end
          @group2_user.shifts.count.must_equal 10
        end
      end

      describe "group 1" do
        before  do
          Shift.all.each do |s|
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 1)
            @sys_config.save!
            if ((s.short_name == 'P1') && (s.can_select(@group1_user) == true))
              @group1_user.shifts << s
              @last_group1_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @group1_user.shifts.count.must_equal 5
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 1)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@group1_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@group1_user.shifts.include?(s))
            s.can_select(@group1_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 2)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@group1_user)
              @group1_user.shifts << s
            end
          end
          @group1_user.shifts.count.must_equal 10
        end
      end

      describe "rookie" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
          @sys_config.save!
          iCnt = 0
          Shift.all.each do |s|
            iCnt += 1
            next if iCnt < 5

            if ((s.can_select(@rookie_user) == true))
              @rookie_user.shifts << s
              @last_rookie_shift = s
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
            next if s.shift_date < @rookie_user.last_shadow
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
      end
    end

    describe "round 3" do
      describe "group 3" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P3') && (s.can_select(@group3_user) == true))
              @group3_user.shifts << s
              @last_group3_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @group3_user.shifts.count.must_equal 10
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@group3_user).must_equal false
          end
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@group3_user.shifts.include?(s))
            s.can_select(@group3_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            if s.can_select(@group3_user)
              @group3_user.shifts << s
            end
          end
          @group3_user.shifts.count.must_equal 15
        end
      end

      describe "group 2" do
        before  do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            if ((s.short_name == 'P2') && (s.can_select(@group2_user) == true))
              @group2_user.shifts << s
              @last_group2_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @group2_user.shifts.count.must_equal 10
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@group2_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@group2_user.shifts.include?(s))
            s.can_select(@group2_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 3)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@group2_user)
              @group2_user.shifts << s
            end
          end
          @group2_user.shifts.count.must_equal 15
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

      describe "group 1" do
        before  do
          Shift.all.each do |s|
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 2)
            @sys_config.save!
            if ((s.short_name == 'P1') && (s.can_select(@group1_user) == true))
              @group1_user.shifts << s
              @last_group1_shift = s
            end
          end
        end

        it "cannot select shifts until start of my round" do
          @group1_user.shifts.count.must_equal 10
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 2)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@group1_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@group1_user.shifts.include?(s))
            s.can_select(@group1_user).must_equal true
          end
        end

        it 'cannot select more than 5 shifts in round' do
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 3)
          @sys_config.save!

          Shift.all.each do |s|
            if s.can_select(@group1_user)
              @group1_user.shifts << s
            end
          end
          @group1_user.shifts.count.must_equal 15
        end
      end
    end

    describe "round 4" do
        describe "group 3" do
          before  do
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
            @sys_config.save!
            Shift.all.each do |s|
              if ((s.short_name == 'P3') && (s.can_select(@group3_user) == true))
                @group3_user.shifts << s
                @last_group3_shift = s
              end
            end
          end

          it "cannot select shifts until start of my round" do
            @group3_user.shifts.count.must_equal 15
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group3_user).must_equal false
            end
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
            @sys_config.save!
            Shift.all.each do |s|
              next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@group3_user.shifts.include?(s))
              s.can_select(@group3_user).must_equal true
            end
          end

          it 'cannot select more than 3 shifts in round' do
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
            @sys_config.save!
            Shift.all.each do |s|
              if s.can_select(@group3_user)
                @group3_user.shifts << s
              end
            end
            @group3_user.shifts.count.must_equal 18
          end
        end

        describe "group 2" do
          before  do
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 3)
            @sys_config.save!
            Shift.all.each do |s|
              if ((s.short_name == 'P2') && (s.can_select(@group2_user) == true))
                @group2_user.shifts << s
                @last_group2_shift = s
              end
            end
          end

          it "cannot select shifts until start of my round" do
            @group2_user.shifts.count.must_equal 15
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 3)
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group2_user).must_equal false
            end

            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 4)
            @sys_config.save!
            Shift.all.each do |s|
              next if (s.team_leader? || s.shadow? || !s.user_id.nil?|| !@group2_user.shifts.include?(s))
              s.can_select(@group2_user).must_equal true
            end
          end

          it 'cannot select more than 5 shifts in round' do
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 4)
            @sys_config.save!

            Shift.all.each do |s|
              if s.can_select(@group2_user)
                @group2_user.shifts << s
              end
            end
            @group2_user.shifts.count.must_equal 18
          end
        end

        describe "group 1" do
          before  do
            Shift.all.each do |s|
              @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 3)
              @sys_config.save!
              if ((s.short_name == 'P1') && (s.can_select(@group1_user) == true))
                @group1_user.shifts << s
                @last_group1_shift = s
              end
            end
          end

          it "cannot select shifts until start of my round" do
            @group1_user.shifts.count.must_equal 15
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 3)
            @sys_config.save!
            Shift.all.each do |s|
              s.can_select(@group1_user).must_equal false
            end

            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 4)
            @sys_config.save!
            Shift.all.each do |s|
              next if (s.team_leader? || s.shadow? || !s.user_id.nil? || !@group1_user.shifts.include?(s))
              s.can_select(@group1_user).must_equal true
            end
          end

          it 'cannot select more than 5 shifts in round' do
            @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 4)
            @sys_config.save!

            Shift.all.each do |s|
              if s.can_select(@group1_user)
                @group1_user.shifts << s
              end
            end
            @group1_user.shifts.count.must_equal 18
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
          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 3)
          @sys_config.save!
          Shift.all.each do |s|
            s.can_select(@rookie_user).must_equal false
          end

          @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 4)
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

                  if s.can_select(@rookie_user) == false
                    display_user_and_shift(@rookie_user, s)
                  end
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
                  if s.can_select(@rookie_user) == false
                    display_user_and_shift(@rookie_user, s)
                  end
                  s.can_select(@rookie_user).must_equal true
                  @rookie_user.shifts << s
                end
              end
            end
          end

          describe 'non-rookie' do
            it "group1" do
              Shift.all.each do |s|
                next s.short_name == 'SH' || s.short_name == 'TL'
                s.can_select(@group1_user).must_equal true
                @group1_user.shifts << s
              end
            end

            it 'group2' do
              Shift.all.each do |s|
                next s.short_name == 'SH' || s.short_name == 'TL'
                s.can_select(@group2_user).must_equal true
                @group2_user.shifts << s
              end
            end

            it 'group 3' do
              Shift.all.each do |s|
                next s.short_name == 'SH' || s.short_name == 'TL'
                s.can_select(@group3_user).must_equal true
                @group3_user.shifts << s
              end

            end
          end
        end
    end

  end
end
