require "test_helper"

class ShiftsHelperTest < ActionView::TestCase

  before do
    @sys_config = SysConfig.first
    @newer_user = User.find_by_name('g3')
    @middle_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g1')
    @team_leader = User.find_by_name('teamlead')

    @a1 = ShiftType.find_by_short_name('A1')
    @tl = ShiftType.find_by_short_name('TL')
    @oc = ShiftType.find_by_short_name('OC')

    Timecop.return
    Timecop.freeze(Date.parse("#{Date.today.year}-10-01"))



    @start_date = (Date.today() + 20.days)

    @pre_bingo_date = Date.today() + 1.day
    @round1_sr_date = Date.today()
    @round1_date = Date.today() - 1.day
    @round2_date = Date.today() - 3.days
    @round3_date = Date.today() - 6.days
    @round4_date = Date.today() - 9.days
    @after_bingo_date = Date.today - 12.day
  end

  after do
    Timecop.return
  end

  describe 'can_drop' do
    describe 'all hosts' do
      it 'cannot drop shifts within two week limit' do
        # set bingo to start 6 rounds ago
        @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 6)
        @sys_config.save!

        # create 3 other shifts and select by other hosts (shift date 1 week out)
        @a1shift = FactoryBot.create(:shift, :shift_date => Date.today + 1.week,
                                     :shift_type_id => @a1.id, :user_id => @newer_user.id)
        @ocshift = FactoryBot.create(:shift, :shift_date => Date.today + 1.week,
                                     :shift_type_id => @oc.id, :user_id => @middle_user.id)
        @a2shift = FactoryBot.create(:shift, :shift_date => Date.today + 1.week,
                                     :shift_type_id => @a1.id, :user_id => @senior_user.id)

        # can not drop any shifts
        @a1shift.can_drop(@newer_user).must_equal false
        @ocshift.can_drop(@middle_user).must_equal false
        @a2shift.can_drop(@senior_user).must_equal false
      end
    end

    describe 'non-rookies' do
      it 'can drop any shifts outside of 2 week window' do
        @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@senior_user, 6)
        @sys_config.save!

        # create 3 other shifts and select by other hosts (shift date 1 week out)
        @a1shift = FactoryBot.create(:shift, :shift_date => Date.today + 3.week,
                                     :shift_type_id => @a1.id, :user_id => @newer_user.id)
        @ocshift = FactoryBot.create(:shift, :shift_date => Date.today + 3.week,
                                     :shift_type_id => @oc.id, :user_id => @middle_user.id)
        @a2shift = FactoryBot.create(:shift, :shift_date => Date.today + 3.week,
                                     :shift_type_id => @a1.id, :user_id => @senior_user.id)

        # can  drop any shifts
        @a1shift.can_drop(@newer_user).must_equal true
        @ocshift.can_drop(@middle_user).must_equal true
        @a2shift.can_drop(@senior_user).must_equal true
      end

    end
  end

  describe 'get current round' do
    it 'sets round correctly for senior users' do
      HostUtility.get_current_round(@start_date,
                                    Date.today(), @senior_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 19.days, @senior_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 20.days, @senior_user).must_equal 1
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 21.days, @senior_user).must_equal 1
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 22.days, @senior_user).must_equal 2
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 23.days, @senior_user).must_equal 2
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 24.days, @senior_user).must_equal 3
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 25.days, @senior_user).must_equal 3
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 26.days, @senior_user).must_equal 4
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 45.days, @senior_user).must_equal 4
    end

    it 'sets round correctly for junior users' do
      HostUtility.get_current_round(@start_date,
                                    Date.today(), @middle_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 19.days, @middle_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 20.days, @middle_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 21.days, @middle_user).must_equal 1
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 22.days, @middle_user).must_equal 1
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 23.days, @middle_user).must_equal 2
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 24.days, @middle_user).must_equal 2
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 25.days, @middle_user).must_equal 3
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 26.days, @middle_user).must_equal 3
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 45.days, @middle_user).must_equal 4
    end

    it 'sets round correctly for freshmen users' do
      HostUtility.get_current_round(@start_date,
                                    Date.today(), @newer_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 19.days, @newer_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 20.days, @newer_user).must_equal 0
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 21.days, @newer_user).must_equal 1
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 22.days, @newer_user).must_equal 1
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 23.days, @newer_user).must_equal 2
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 24.days, @newer_user).must_equal 2
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 25.days, @newer_user).must_equal 3
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 26.days, @newer_user).must_equal 3
      HostUtility.get_current_round(@start_date,
                                    Date.today() + 45.days, @newer_user).must_equal 4
    end
  end

  describe "can_select" do
    describe "team leaders" do
      # Team leaders can select shifts at will regardless of bingo date
      before do
        @sys_config.bingo_start_date = @pre_bingo_date
        @sys_config.save!
      end

      it 'with empty slate, can only select TL' do
        tl_shift = Shift.find_by(short_name: 'TL')
        tl_shift.can_select(@team_leader,
                     HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                         "Cannot select when should: TEAM LEADER.  SHIFT: #{tl_shift.short_name}")
        a1_shift = Shift.find_by(short_name: 'A1')
        a1_shift.can_select(@team_leader,
                     HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                         "Can select when shouldn't: TEAM LEADER.  SHIFT: #{a1_shift.short_name}")

        oc_shift = Shift.find_by(short_name: 'OC')
        oc_shift.can_select(@team_leader,
                      HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                          "Can select when shouldn't: TEAM LEADER.  SHIFT: #{oc_shift.short_name}")
      end

      it 'can select 7 TL shifts before bingo end' do
        Shift.all.each do |s|
          if @team_leader.shifts.count <= 8
            # can select TL
            if s.team_leader?
            s.can_select(@team_leader,
                        HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                            "Cannot select when should: TEAM LEADER.  SHIFT: #{s.short_name}")
              @team_leader.shifts << s
            else
              s.can_select(@team_leader,
                        HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                            "Can select when shouldn't: TEAM LEADER.  SHIFT: #{s.short_name}")
            end
          end
        end
        assert_equal(9, @team_leader.shifts.count)
      end

      it 'can select 9 OC shifts before bingo end (after TLs)' do
        # add 7 TL shifts to team leader
        for s in 1..7 do
          s_date = Date.today() + s.days
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>s_date,
                                   :shift_status_id => 1,
                                   :day_of_week=>s_date.strftime("%a"))
          @team_leader.shifts << new_shift
        end
        assert_equal(9, @team_leader.shifts.count)

        Shift.all.each do |s|
          if @team_leader.shifts.count < 18
            # can select OC, cannot select others
            if s.on_call?
              s.can_select(@team_leader,
                HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                    "Cannot select when should: TEAM LEADER.  SHIFT: #{s.short_name}")
              @team_leader.shifts << s
            else
              # cannot select non OC shifts
              s.can_select(@team_leader,
                HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                    "Can select when shouldn't: TEAM LEADER.  SHIFT: #{s.short_name}")
            end
          else
            # cannot select any shifts
            s.can_select(@team_leader,
                HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                    "Can select when shouldn't: TEAM LEADER.  SHIFT: #{s.short_name}")
           end
        end
      end

      it 'cannot pick disabled shifts at any time' do
        shift = Shift.find_by(short_name: 'TL')
        shift.can_select(@team_leader,
               HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                  "Cannot select when should: TEAM LEADER.  SHIFT: #{shift.short_name}")
        shift.disabled = true
        shift.save
        shift.can_select(@team_leader,
               HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                   "Can select when shouldn't: TEAM LEADER.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift already taken' do
        shift = Shift.find_by(short_name: 'TL')
        shift.can_select(@team_leader,
               HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                    "Cannot select when should: TEAM LEADER.  SHIFT: #{shift.short_name}")
        @team_leader.shifts << shift
        shift.can_select(@team_leader,
               HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                    "Can select when shouldn't: TEAM LEADER.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift if already working that day' do
        shift = Shift.find_by(short_name: 'TL')
        shift.can_select(@team_leader,
                HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                     "Cannot select when should: TEAM LEADER.  SHIFT: #{shift.short_name}")
        @team_leader.shifts << shift
        new_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@tl.id,
                                 :shift_date=>shift.shift_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>shift.day_of_week)
        new_shift.can_select(@team_leader,
                 HostUtility.can_select_params_for(@team_leader)).must_equal(false,
                      "Can select when shouldn't: TEAM LEADER.  SHIFT: #{new_shift.short_name}")
      end

      it 'can select any shift after bingo done' do
        # populate user with all 18 shifts
        for i in 0..6 do
          s_date = Date.today + i.days
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>s_date,
                                   :shift_status_id => 1,
                                   :day_of_week=>s_date.strftime("%a"))
          @team_leader.shifts << new_shift
        end

        for i in 7..15 do
          s_date = Date.today + i.days
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>s_date,
                                   :shift_status_id => 1,
                                   :day_of_week=>s_date.strftime("%a"))
          @team_leader.shifts << new_shift
        end
        assert_equal(18, @team_leader.shifts.count)

        # set time for after bingo
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        s_date = Date.today
        tl_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@tl.id,
                                 :shift_date=>s_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>s_date.strftime("%a"))
        oc_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@oc.id,
                                 :shift_date=>s_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>s_date.strftime("%a"))
        a1_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@a1.id,
                                 :shift_date=>s_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>s_date.strftime("%a"))
        # verify can select TL
        tl_shift.can_select(@team_leader,
            HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                "Cannot select when should: TEAM LEADER.  SHIFT: #{tl_shift.short_name}")

        # verify can select OC
        oc_shift.can_select(@team_leader,
            HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                "Cannot select when should: TEAM LEADER.  SHIFT: #{oc_shift.short_name}")

        # verify can select A1
        a1_shift.can_select(@team_leader,
            HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                "Cannot select when should: TEAM LEADER.  SHIFT: #{a1_shift.short_name}")
      end

      it "cannot select more than 18 shifts during bingo" do
        @sys_config.bingo_start_date = @round1_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date,
                                      Date.today, @team_leader).must_equal 1
        for i in 0..6 do
          s_date = Date.today + i.days
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>s_date,
                                   :shift_status_id => 1,
                                   :day_of_week=>s_date.strftime("%a"))
          @team_leader.shifts << new_shift
        end

        for i in 7..15 do
          s_date = Date.today + i.days
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>s_date,
                                   :shift_status_id => 1,
                                   :day_of_week=>s_date.strftime("%a"))
          @team_leader.shifts << new_shift
        end
        assert_equal(18, @team_leader.shifts.count)

        new_shift = FactoryBot.create(:shift, shift_type_id: @tl.id,
                       shift_date: @team_leader.shifts.map(&:shift_date).max + 1.day)
        new_shift.can_select(@team_leader,
                       HostUtility.can_select_params_for(@team_leader)).must_equal false
      end

      it 'can work on a meeting day' do
        mtg = ShiftType.find_by(short_name: 'M2')
        shift_date = Date.today + 50.days
        mtg_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>mtg.id,
                                 :shift_date=>shift_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>shift_date.strftime("%a"))
        @team_leader.shifts << mtg_shift
        new_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@tl.id,
                                 :shift_date=>shift_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>shift_date.strftime("%a"))
        new_shift.can_select(@team_leader,
                HostUtility.can_select_params_for(@team_leader)).must_equal(true,
                     "Cannot select when should: TEAM LEADER.  SHIFT: #{new_shift.short_name}")
      end
    end

    describe 'group 1' do
      before do
        @work_user = @senior_user
      end

      it 'cannot pick disabled shifts at any time' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(true,
                             "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
        shift.disabled = true
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                             "Can select when shouldn't: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick team leader shifts at any time' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'TL')
        shift.shift_date = shift.shift_date + 10.days
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                              "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift already taken' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.shift_date = shift.shift_date + 10.days
        shift.user_id = @middle_user.id
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                          "Can select when shouldn't: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift if already working that day' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(true,
                              "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
        @work_user.shifts << shift
        new_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@tl.id,
                                 :shift_date=>shift.shift_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>shift.day_of_week)
        new_shift.can_select(@work_user,
                             HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                  "Can select when shouldn't: SENIOR.  SHIFT: #{new_shift.short_name}")
      end

      it 'can select 5 A1 shifts in round 1' do
        round_1_date = HostUtility.date_for_round(@work_user, 1)
        Timecop.return
        Timecop.freeze(round_1_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)) == true
            assert_equal('A1', s.short_name)
            @work_user.shifts << s
          end
        end
        assert_equal(7, @work_user.shifts.count)
      end

      it 'can select 1 A1 shift and 4 OC shifts in round 2' do
        round_2_date = HostUtility.date_for_round(@work_user, 2)
        Timecop.return
        Timecop.freeze(round_2_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s
            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
           end
        end
        assert_equal(12, @work_user.shifts.count)
        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(6, a1_count)
        assert_equal(4, oc_count)
      end

      it 'can select 6 OC shifts in round 3' do
        round_3_date = HostUtility.date_for_round(@work_user, 3)
        Timecop.return
        Timecop.freeze(round_3_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s

            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(18, @work_user.shifts.count)
        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(6, a1_count)
        assert_equal(10, oc_count)
      end

      it 'cannot select OC shift if A1 < 6 - even if OCs have been picked (i.e. A1 dropped during bingo)' do
        round_2_date = HostUtility.date_for_round(@work_user, 2)
        Timecop.return
        Timecop.freeze(round_2_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s
            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(12, @work_user.shifts.count)

        a1_shift = @work_user.shifts.find_by(short_name: 'A1')
        a1_shift.user_id = nil
        a1_shift.save
        @work_user.shifts.reload

        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(5, a1_count)
        assert_equal(4, oc_count)

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            s.short_name.must_equal 'A1'
          end
        end

        Timecop.return
        Timecop.freeze(HostUtility.date_for_round(@work_user, 5))
        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            s.short_name.must_equal 'A1'
          end
        end
      end
    end

    describe 'group 2' do
      before do
        @work_user = @middle_user
      end

      it 'cannot pick disabled shifts at any time' do
        Timecop.return
        Timecop.freeze(HostUtility.date_for_round(@work_user, 5))
        shift = Shift.find_by(short_name: 'A1')
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(true,
                               "Cannot select when should: MIDDLE.  SHIFT: #{shift.short_name}")
        shift.disabled = true
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                "Can select when shouldn't: MIDDLE.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick team leader shifts at any time' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'TL')
        shift.shift_date = shift.shift_date + 10.days
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                                                                   "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift already taken' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.shift_date = shift.shift_date + 10.days
        shift.user_id = @middle_user.id
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                                                                   "Can select when shouldn't: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift if already working that day' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(true,
                                                                                   "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
        @work_user.shifts << shift
        new_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@tl.id,
                                 :shift_date=>shift.shift_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>shift.day_of_week)
        new_shift.can_select(@work_user,
                             HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                                                                       "Can select when shouldn't: SENIOR.  SHIFT: #{new_shift.short_name}")
      end

      it 'can select 5 A1 shifts in round 1' do
        round_1_date = HostUtility.date_for_round(@work_user, 1)
        Timecop.return
        Timecop.freeze(round_1_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            assert_equal('A1', s.short_name)
            @work_user.shifts << s
          end
        end
        assert_equal(7, @work_user.shifts.count)
      end

      it 'can select 1 A1 shift and 4 OC shifts in round 2' do
        round_2_date = HostUtility.date_for_round(@work_user, 2)
        Timecop.return
        Timecop.freeze(round_2_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s
            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(12, @work_user.shifts.count)
        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(6, a1_count)
        assert_equal(4, oc_count)
      end

      it 'can select 6 OC shifts in round 3' do
        round_3_date = HostUtility.date_for_round(@work_user, 3)
        Timecop.return
        Timecop.freeze(round_3_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s

            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(18, @work_user.shifts.count)
        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(6, a1_count)
        assert_equal(10, oc_count)
      end

      it 'cannot select OC shift if A1 < 6 - even if OCs have been picked (i.e. A1 dropped during bingo)' do
        round_2_date = HostUtility.date_for_round(@work_user, 2)
        Timecop.return
        Timecop.freeze(round_2_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s
            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(12, @work_user.shifts.count)

        a1_shift = @work_user.shifts.find_by(short_name: 'A1')
        a1_shift.user_id = nil
        a1_shift.save
        @work_user.shifts.reload

        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(5, a1_count)
        assert_equal(4, oc_count)

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            s.short_name.must_equal 'A1'
          end
        end

        Timecop.return
        Timecop.freeze(HostUtility.date_for_round(@work_user, 5))
        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            s.short_name.must_equal 'A1'
          end
        end
      end
    end

    describe 'group 3' do
      before do
        @work_user = @newer_user
      end

      it 'cannot pick disabled shifts at any time' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(true,
                                                                                   "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
        shift.disabled = true
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                                                                   "Can select when shouldn't: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick team leader shifts at any time' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'TL')
        shift.shift_date = shift.shift_date + 10.days
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                                                                   "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift already taken' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.shift_date = shift.shift_date + 10.days
        shift.user_id = @middle_user.id
        shift.save
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                                                                   "Can select when shouldn't: SENIOR.  SHIFT: #{shift.short_name}")
      end

      it 'cannot pick shift if already working that day' do
        Timecop.return
        Timecop.freeze(Date.today + 40.days)
        shift = Shift.find_by(short_name: 'A1')
        shift.can_select(@work_user,
                         HostUtility.can_select_params_for(@work_user)).must_equal(true,
                                                                                   "Cannot select when should: SENIOR.  SHIFT: #{shift.short_name}")
        @work_user.shifts << shift
        new_shift = Shift.create(:user_id=>nil,
                                 :shift_type_id=>@tl.id,
                                 :shift_date=>shift.shift_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>shift.day_of_week)
        new_shift.can_select(@work_user,
                             HostUtility.can_select_params_for(@work_user)).must_equal(false,
                                                                                       "Can select when shouldn't: SENIOR.  SHIFT: #{new_shift.short_name}")
      end

      it 'can select 5 A1 shifts in round 1' do
        round_1_date = HostUtility.date_for_round(@work_user, 1)
        Timecop.return
        Timecop.freeze(round_1_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            assert_equal('A1', s.short_name)
            @work_user.shifts << s
          end
        end
        assert_equal(7, @work_user.shifts.count)
      end

      it 'can select 1 A1 shift and 4 OC shifts in round 2' do
        round_2_date = HostUtility.date_for_round(@work_user, 2)
        Timecop.return
        Timecop.freeze(round_2_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s
            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(12, @work_user.shifts.count)
        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(6, a1_count)
        assert_equal(4, oc_count)
      end

      it 'can select 6 OC shifts in round 3' do
        round_3_date = HostUtility.date_for_round(@work_user, 3)
        Timecop.return
        Timecop.freeze(round_3_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s

            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(18, @work_user.shifts.count)
        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(6, a1_count)
        assert_equal(10, oc_count)
      end

      it 'cannot select OC shift if A1 < 6 - even if OCs have been picked (i.e. A1 dropped during bingo)' do
        round_2_date = HostUtility.date_for_round(@work_user, 2)
        Timecop.return
        Timecop.freeze(round_2_date)

        for i in 1..25 do
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@a1.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@oc.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
          new_shift = Shift.create(:user_id=>nil,
                                   :shift_type_id=>@tl.id,
                                   :shift_date=>Date.today + i.days,
                                   :shift_status_id => 1,
                                   :day_of_week=> (Date.today + i.days).strftime("%a"))
        end

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            a1_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'A1' }.count
            oc_count = @work_user.shifts.to_a.delete_if {|s| s.short_name != 'OC' }.count
            @work_user.shifts << s
            assert_equal('A1', s.short_name) if a1_count < 6
            assert_equal('OC', s.short_name) if a1_count >= 6
          end
        end
        assert_equal(12, @work_user.shifts.count)

        a1_shift = @work_user.shifts.find_by(short_name: 'A1')
        a1_shift.user_id = nil
        a1_shift.save
        @work_user.shifts.reload

        counts = Hash.new 0
        @work_user.shifts.map(&:short_name).each {|s| counts[s] += 1 }
        a1_count = counts['A1']
        oc_count = counts['OC']
        assert_equal(5, a1_count)
        assert_equal(4, oc_count)

        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            s.short_name.must_equal 'A1'
          end
        end

        Timecop.return
        Timecop.freeze(HostUtility.date_for_round(@work_user, 5))
        Shift.all.each do |s|
          if s.can_select(@work_user,
                          HostUtility.can_select_params_for(@work_user)) == true
            s.short_name.must_equal 'A1'
          end
        end
      end
    end
  end
end
