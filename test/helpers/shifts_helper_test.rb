require "test_helper"

class ShiftsHelperTest < ActionView::TestCase

  before do
    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @newer_user = User.find_by_name('g3')
    @middle_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g1')
    @team_leader = User.find_by_name('teamlead')

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

      it "can select shifts before bingo if not TL shift" do
        shifts = Shift.all
        unselected = shifts.to_a.delete_if {|s| !s.user_id.nil? || @team_leader.is_working?(s.shift_date) || s.shadow? }

        unselected.each do |s|
          s.can_select(@team_leader).must_equal true
        end
      end

      it "can select shifts after bingo if not TL shift and not too many for round" do
        @sys_config.bingo_start_date = Date.today - 1.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 1

        Shift.all.each do |s|
          if (s.short_name != "SH") && (!@team_leader.is_working?(s.shift_date))
            s.can_select(@team_leader).must_equal true
          else
            s.can_select(@team_leader).must_equal false
          end
        end
      end
    end

    describe "regular hosts" do
      it "cannot pick shifts prior to bingo start" do
        @sys_config.bingo_start_date = Date.today + 1.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 0

        Shift.all.each do |s|
          next if s.short_name == "TL"
          s.can_select(@senior_user).must_equal false
        end
      end

      it "can pick up to 5 shifts in round 1" do
        @sys_config.bingo_start_date = Date.today
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 1

        Shift.all.each do |s|
          next if (s.short_name == "TL") || (s.short_name == 'SH') || @senior_user.is_working?(s.shift_date)

          can_select = s.can_select(@senior_user)
          if @senior_user.shifts.count < 5
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick up to 10 shifts in round 2" do
        @sys_config.bingo_start_date = Date.today - 3.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 2

        Shift.all.each do |s|
          next if (s.short_name == "TL") || (s.short_name == 'SH') || @senior_user.is_working?(s.shift_date)

          can_select = s.can_select(@senior_user)
          if @senior_user.shifts.count < 10
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick up to 15 shifts in round 3" do
        @sys_config.bingo_start_date = Date.today - 6.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 3

        Shift.all.each do |s|
          next if (s.short_name == "TL") || (s.short_name == 'SH') || @senior_user.is_working?(s.shift_date)

          can_select = s.can_select(@senior_user)
          if @senior_user.shifts.count < 15
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick up to 18 shifts in round 4" do
        @sys_config.bingo_start_date = Date.today - 9.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 4

        Shift.all.each do |s|
          next if (s.short_name == "TL") || (s.short_name == 'SH') || @senior_user.is_working?(s.shift_date)

          can_select = s.can_select(@senior_user)
          if @senior_user.shifts.count < 20
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick over 18 shifts after round 4" do
        @sys_config.bingo_start_date = Date.today - 12.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 5

        Shift.all.each do |s|
          next if (s.short_name == "TL") || (s.short_name == 'SH') || @senior_user.is_working?(s.shift_date)

          can_select = s.can_select(@senior_user)
          can_select.must_equal true
          @senior_user.shifts << s
        end
      end
    end

    describe 'rookie hosts' do
      it 'test for round two shifts' do
        @sys_config.bingo_start_date = Date.today - 5.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 2

        Shift.all.each do |s|
          if @rookie_user.shifts.count == 5
            next if s.shift_date < (@rookie_user.last_shadow + 8.days)
          end

          if s.can_select(@rookie_user)
            @rookie_user.shifts << s
          end

          break if @rookie_user.shifts.count == 9
        end

        icnt = 0
        @rookie_user.shifts.each do |s|
          if icnt < 4
            s.shadow?.must_equal true
          else
            s.rookie_training_type?.must_equal true
          end
          icnt += 1
        end

        pshift = FactoryGirl.create(:shift, short_name: "P1", shift_type: @p1, shift_date: @rookie_user.last_shadow + 3.days)
        pshift.can_select(@rookie_user).must_equal false

        gshift = FactoryGirl.create(:shift, short_name: "G1", shift_type: @g1, shift_date: @rookie_user.last_shadow + 3.days)
        gshift.can_select(@rookie_user).must_equal true
      end

      it "should never allow selecting non-training shifts prior to last training shift" do
        @sys_config.bingo_start_date = Date.today - 20.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 7

        last_tr_dt = nil
        Shift.all.each do |s|
          if s.can_select(@rookie_user)
            @rookie_user.shifts << s
            last_tr_dt = @rookie_user.last_training_date
          end
        end

        arr = @rookie_user.shifts.to_a
        target_dt = arr[7]
        arr.delete_at(7)

        pshift = FactoryGirl.create(:shift, short_name: "P1", shift_type: @p1, shift_date: target_dt.shift_date)
        pshift.can_select(@rookie_user).must_equal false
      end


      it 'test for last_shadow, last_trainnig_date ' do
        @sys_config.bingo_start_date = Date.today - 20.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 7

        Shift.all.each do |s|
          @rookie_user.shifts << s if s.can_select(@rookie_user)
        end

        sh_dt = nil
        tr_dt = nil
        tr_cnt = 0

        @rookie_user.shifts.each do |s|
          if s.shadow?
            sh_dt = s.shift_date
          elsif s.rookie_training_type?
            tr_dt = s.shift_date
            tr_cnt += 1
            break if tr_cnt == 6
          else
            assert_equal(true, false, "Invalid shift type found in test for last shadow and last training date")
          end
        end
        assert_equal(tr_dt, @rookie_user.last_training_date,
                     "Error - last training date (#{@rookie_user.last_training_date} doesn't match: #{tr_dt}")
        assert_equal(sh_dt, @rookie_user.last_shadow,
                     "Error - last shadow date (#{@rookie_user.last_shadow} doesn't match: #{sh_dt}")
      end

      it 'test for round 3' do
        @sys_config.bingo_start_date = Date.today - 8.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 3

        training_gap = nil
        Shift.all.each do |s|
          if @rookie_user.shifts.count == 5
            next if s.shift_date < (@rookie_user.last_shadow + 3.days)
          end

          if @rookie_user.shifts.count == 9
            training_gap = @rookie_user.shifts.last.shift_date + 3.days
            next if s.shift_date < (@rookie_user.shifts.last.shift_date + 3.days)
          end

          if s.can_select(@rookie_user)
            @rookie_user.shifts << s
          end

          break if @rookie_user.shifts.count == 14
        end

        pshift = FactoryGirl.create(:shift, short_name: "P1", shift_type: @p1, shift_date: @rookie_user.last_shadow + 3.days)
        pshift.can_select(@rookie_user).must_equal false

        pshift2 = FactoryGirl.create(:shift, short_name: "P1", shift_type: @p1, shift_date: training_gap + 3.days)
        pshift2.can_select(@rookie_user).must_equal false

        pshift3 = FactoryGirl.create(:shift, short_name: "P1", shift_type: @p1, shift_date: @rookie_user.shifts.last.shift_date + 1.day)
        pshift3.can_select(@rookie_user).must_equal true
      end

      it 'must not be able to pick non-shadows before last shadow shift' do
        @sys_config.bingo_start_date = Date.today - 11.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 4
        Shift.all.each do |s|
          last_shadow = @rookie_user.last_shadow
          if @rookie_user.shadow_count == 3
            next if s.shift_date < last_shadow + 4.days
          end

          can_select = s.can_select(@rookie_user)
          if can_select
            @rookie_user.shifts << s if can_select
          end
        end

        @rookie_user.shifts.count.must_equal 20
        @rookie_user.shadow_count.must_equal 4

        @sys_config.bingo_start_date = Date.today - 20.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 7

        last_shadow = @rookie_user.last_shadow
        Shift.all.each do |s|
          if s.shift_date < last_shadow
            s.can_select(@rookie_user).must_equal false
          end
        end
      end

      it 'test before round one shift selections' do
        @sys_config.bingo_start_date = Date.today + 1.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 0

        shift_count = @rookie_user.shifts.to_a.delete_if {|s| s.meeting? }.count

        shift_count.must_equal(0)
        @rookie_user.shadow_count.must_equal(0)

        Shift.all.each do |s|
          can_select = s.can_select(@rookie_user)

          if s.shadow? == true
            if @rookie_user.is_working?(s.shift_date)
              can_select.must_equal(false)
              next
            else
              can_select.must_equal(true)
            end

            @rookie_user.shifts << s
            shift_count += 1
            break if shift_count == 4
            next
          else
            can_select.must_equal(false)
          end
        end

        shift_count.must_equal(4)

        Shift.all.each do |s|
          can_select = s.can_select(@rookie_user)
          can_select.must_equal(false) if @rookie_user.is_working?(s.shift_date)
          can_select.must_equal(false) if s.shadow?
          can_select.must_equal(false) if shift_count >= 5
          can_select.must_equal(false) if !s.rookie_training_type?

          if can_select == true
            shift_count += 1
            @rookie_user.shifts << s
          end

        end
      end

      it "must be able to pick 5 shifts in round 1" do
        @sys_config.bingo_start_date = Date.today - 2.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 1
        Shift.all.each do |s|
          can_select = s.can_select(@rookie_user)

          @rookie_user.shifts << s if can_select
        end
        shift_count = @rookie_user.shifts.to_a.delete_if {|s| s.meeting? }.count
        shift_count.must_equal(5)
      end

      it 'must be able to pick 10 shifts in round 2' do
        @sys_config.bingo_start_date = Date.today - 5.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 2
        Shift.all.each do |s|
          can_select = s.can_select(@rookie_user)

          @rookie_user.shifts << s if can_select
        end
        shift_count = @rookie_user.shifts.to_a.delete_if {|s| s.meeting? }.count
        shift_count.must_equal(10)
      end

      it 'must be able to pick 15 shifts in round 3' do
        @sys_config.bingo_start_date = Date.today - 8.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 3
        Shift.all.each do |s|
          can_select = s.can_select(@rookie_user)

          @rookie_user.shifts << s if can_select
        end
        shift_count = @rookie_user.shifts.to_a.delete_if {|s| s.meeting? }.count
        shift_count.must_equal(15)
      end

      it 'must be able to pick 1 shift in round 4' do
        @sys_config.bingo_start_date = Date.today - 11.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 4
        Shift.all.each do |s|
          can_select = s.can_select(@rookie_user)

          @rookie_user.shifts << s if can_select
        end
        shift_count = @rookie_user.shifts.to_a.delete_if {|s| s.meeting? }.count
        shift_count.must_equal(20)
      end
    end

    describe 'trainer hosts' do
      before do
        @trainer = @senior_user
        @trainer.add_role :trainer

        @tr = FactoryGirl.create(:shift_type, :short_name => 'TR')

        @sys_config.bingo_start_date = Date.today - 3.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @trainer).must_equal 2

        @t_shifts = []
        (1..5).each do |n|
          @trainer_shift = FactoryGirl.create(:shift, :shift_date => Date.today + 2.weeks + n.days,
                                              :shift_type_id => @tr.id, :user_id => nil)
          @t_shifts << @trainer_shift
        end
      end

      it 'no one can select trainer shifts' do
        @t_shifts.each do |ts|
          ts.can_select(@trainer).must_equal true
          ts.can_select(@rookie_user).must_equal false
          ts.can_select(@newer_user).must_equal false
          ts.can_select(@middle_user).must_equal false
        end
      end

      it 'trainer shifts should not count against host quota' do
        @t_shifts.each do |ts|
          ts.user_id = @trainer.id
          ts.save!
        end

        @trainer.shifts.count.must_equal 5

        Shift.all.each do |s|
          can_select = s.can_select(@trainer)
          if can_select
            @trainer.shifts << s if can_select
          end
        end

        @trainer.shifts.count.must_equal 15
      end
    end

    describe 'round 4' do
      it 'all users should have same start da' do
        @sys_config.bingo_start_date = Date.today - 9.day
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 4
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @middle_user).must_equal 4
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @newer_user).must_equal 4
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @rookie_user).must_equal 4
      end
    end
  end


end
