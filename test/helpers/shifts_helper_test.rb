require "test_helper"

class ShiftsHelperTest < ActionView::TestCase

  before do
    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @newer_user = User.find_by_name('g3')
    @middle_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g1')
    @team_leader = User.find_by_name('teamlead')
    @surveyor = User.find_by_name('surveyor')
    @trainer = User.find_by_name('trainer')

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
    @sv = ShiftType.find_by(short_name: "SV")
    @tr = ShiftType.find_by(short_name: "TR")

    Timecop.freeze(Date.parse("2017-10-01"))
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
        @sys_config.bingo_start_date = @pre_bingo_date
        @sys_config.save!
        Shift.all.each do |s|
          if s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader))
            @team_leader.shifts << s if s.short_name == "TL"
            break if @team_leader.shifts.count >= 12
          else
            s.short_name.wont_equal "TL"
          end
        end
      end

      it 'must not be able to select disabled shifts' do
        shifts = Shift.all
        unselected = shifts.to_a.delete_if {|s| !s.user_id.nil? || @team_leader.is_working?(s.shift_date)}

        unselected.each do |s|
          if s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)) == true
            s.disabled = true
            s.save
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
          end

        end
      end

      it 'must have 12 shifts after setup' do
        @team_leader.shifts.count.must_equal 12
      end

      it "can select shifts before bingo if not TL shift" do
        shifts = Shift.all
        unselected = shifts.to_a.delete_if {|s| !s.user_id.nil? || @team_leader.is_working?(s.shift_date)}

        unselected.each do |s|
          if s.trainer? || s.training? || s.meeting? || s.survey?
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
          else
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal true
          end
        end
      end

      it "cannot select more than 20 shifts during bingo" do
        @sys_config.bingo_start_date = @round1_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 1

        Shift.all.each do |s|
          next if s.meeting?

          if (!@team_leader.is_working?(s.shift_date) && !s.trainer? && !s.training? && !s.survey? && @team_leader.shifts.count < 20)
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal true
            @team_leader.shifts << s
          else
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
          end
        end
        (@team_leader.shifts.count <= 20).must_equal true

        new_shift = FactoryGirl.create(:shift, shift_type_id: @tl.id, shift_date: @team_leader.shifts.map(&:shift_date).max + 1.day)
        new_shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
      end

      it "cannot select training or trainer shifts" do
        @sys_config.bingo_start_date = @round4_date
        @sys_config.save!
        round = HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 4

        # create trainer and training shifts
        @tr = ShiftType.find_by(short_name: 'TR')
        t1type = FactoryGirl.create(:shift_type, short_name: 'T1')
        t2type = FactoryGirl.create(:shift_type, short_name: 'T2')
        t3type = FactoryGirl.create(:shift_type, short_name: 'T3')
        training_shifts = []
        (1..5).each do |n|
          trainer_shift = FactoryGirl.create(:shift, :shift_date => Date.today + 2.weeks + n.days,
                                             :shift_type_id => @tr.id, :user_id => nil)
          t1_shift = FactoryGirl.create(:shift, shift_date: Date.today + n.days, shift_type_id: t1type.id)
          t2_shift = FactoryGirl.create(:shift, shift_date: Date.today + n.days, shift_type_id: t2type.id)
          t3_shift = FactoryGirl.create(:shift, shift_date: Date.today + n.days, shift_type_id: t3type.id)
          training_shifts << trainer_shift
          training_shifts << t1_shift
          training_shifts << t2_shift
          training_shifts << t3_shift
        end

        training_shifts.each do |s|
          s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
        end
      end
    end

    describe "regular hosts" do
      it "cannot pick shifts prior to bingo start" do
        @sys_config.bingo_start_date = @pre_bingo_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 0

        Shift.all.each do |s|
          s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end
      end

      it 'cannot pick shifts prior to todays date' do
        @sys_config.bingo_start_date = @after_bingo_date
        @sys_config.save!

        s1 = FactoryGirl.create(:shift, shift_date: Date.today - 5.days, shift_type_id: @p1.id)
        s2 = FactoryGirl.create(:shift, shift_date: Date.today - 4.days, shift_type_id: @p1.id)
        s3 = FactoryGirl.create(:shift, shift_date: Date.today - 3.days, shift_type_id: @p1.id)
        s4 = FactoryGirl.create(:shift, shift_date: Date.today - 2.days, shift_type_id: @p1.id)
        s5 = FactoryGirl.create(:shift, shift_date: Date.today - 1.days, shift_type_id: @p1.id)
        s6 = FactoryGirl.create(:shift, shift_date: Date.today, shift_type_id: @p1.id)
        s1.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        s2.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        s3.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        s4.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        s5.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        s6.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal true
      end

      it "can pick up to 5 shifts in round 1" do
        @sys_config.bingo_start_date = @round1_sr_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 1

        Shift.all.each do |s|
          next if (s.team_leader?) || @senior_user.is_working?(s.shift_date) || s.meeting? || s.training? || s.trainer?

          can_select = s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user))
          if @senior_user.shifts.count < 7
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick up to 10 shifts in round 2" do
        @sys_config.bingo_start_date = @round2_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 2

        Shift.all.each do |s|
          next if (s.short_name == "TL") || @senior_user.is_working?(s.shift_date) || s.meeting?

          can_select = s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user))
          if @senior_user.shifts.count < 12
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick up to 15 shifts in round 3" do
        @sys_config.bingo_start_date = @round3_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 3

        Shift.all.each do |s|
          next if (s.short_name == "TL") || @senior_user.is_working?(s.shift_date) || s.meeting?

          can_select = s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user))
          if @senior_user.shifts.count < 17
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick up to 18 shifts in round 4" do
        @sys_config.bingo_start_date = @round4_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 4

        Shift.all.each do |s|
          next if (s.short_name == "TL") || @senior_user.is_working?(s.shift_date) || s.meeting?

          can_select = s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user))
          if @senior_user.shifts.count < 20
            can_select.must_equal true
            @senior_user.shifts << s
          else
            can_select.must_equal false
          end
        end
      end

      it "can pick over 18 shifts after round 4" do
        @sys_config.bingo_start_date = @after_bingo_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 5

        Shift.all.each do |s|
          next if (s.short_name == "TL") || @senior_user.is_working?(s.shift_date) || s.meeting?

          can_select = s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user))

          can_select.must_equal true
          @senior_user.shifts << s
        end

        (@senior_user.shifts.count.> 20).must_equal true
      end
    end

    describe 'trainer hosts' do
      before do
        @tr = ShiftType.find_by(short_name: 'TR')

        @sys_config.bingo_start_date = @round2_date
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
          ts.can_select(@trainer, HostUtility.can_select_params_for(@trainer)).must_equal true
          ts.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          ts.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false
          ts.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false
          ts.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor)).must_equal false
        end
      end

      it "trainers cannot select more than 20 shifts during bingo" do
        (1..20).each do |n|
          @trainer_shift = FactoryGirl.create(:shift, :shift_date => Date.today + 4.weeks + n.days,
                                              :shift_type_id => @tr.id, :user_id => nil)
          @t_shifts << @trainer_shift
        end
        @t_shifts.each do |ts|
          if ts.can_select(@trainer, HostUtility.can_select_params_for(@trainer)) == true
            @trainer.shifts << ts
          end
        end
        @trainer.shifts.count.must_equal 20
        Shift.all.each do |s|
          s.can_select(@trainer, HostUtility.can_select_params_for(@trainer)).must_equal false
        end
      end

      it 'trainer shifts should not count against bingo quota' do
        @t_shifts.each do |ts|
          ts.user_id = @trainer.id
          ts.save!
        end
        @trainer.shifts.count.must_equal 7

        Shift.all.each do |s|
          can_select = s.can_select(@trainer, HostUtility.can_select_params_for(@trainer))
          if can_select
            @trainer.shifts << s if can_select
          end
        end

        @trainer.shifts.count.must_equal 17
      end
    end

    describe 'survey hosts' do
      before do
        @sh = ShiftType.find_by(short_name: "SV")

        @sys_config.bingo_start_date = @round2_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @surveyor).must_equal 2

        @s_shifts = []
        (1..5).each do |n|
          @survey_shift = FactoryGirl.create(:shift, :shift_date => Date.today + 2.weeks + n.days,
                                             :shift_type_id => @sh.id, :user_id => nil)
          @s_shifts << @survey_shift
        end
      end

      it 'no one can select survey shifts' do
        @s_shifts.each do |ss|
          ss.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor)).must_equal true
          ss.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false
          ss.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false
          ss.can_select(@trainer, HostUtility.can_select_params_for(@trainer)).must_equal false
          ss.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end
      end

      it 'surveyor shifts should not count against host quota' do
        @s_shifts.each do |ts|
          # ts.user_id = @surveyor.id
          # ts.save!
          @surveyor.shifts << ts
        end
        @surveyor.shifts.count.must_equal 7

        Shift.all.each do |s|
          can_select = s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          if can_select
            @surveyor.shifts << s if can_select
          end
        end

        @surveyor.shifts.count.must_equal 17
      end

      it 'survey hosts can pick a max of 9 survey shifts during bingo' do
        @sys_config.bingo_start_date = @round4_date
        @sys_config.save!
        (1..5).each do |n|
          @survey_shift = FactoryGirl.create(:shift, :shift_date => Date.today + 6.weeks + n.days,
                                             :shift_type_id => @sh.id, :user_id => nil)
          @s_shifts << @survey_shift
        end
        @s_shifts.each do |ts|
          next unless ts.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          @surveyor.shifts << ts
        end
        @surveyor.shifts.count.must_equal 11

        Shift.all.each do |s|
          can_select = s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          if can_select
            @surveyor.shifts << s if can_select
          end
        end

        @surveyor.shifts.count.must_equal 20
      end
    end

    describe 'rookie hosts' do
      before do
        @sys_config.bingo_start_date = @round2_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @surveyor).must_equal 2

        @tour_shifts = Shift.where("short_name like 'P%'")
      end

      def create_t1_shifts
        first_date = Shift.where("short_name not like 'M%'").order(:shift_date).first.shift_date
        t1type = FactoryGirl.create(:shift_type, short_name: 'T1')
        (1..5).each do |n|
          FactoryGirl.create(:shift, shift_date: first_date + n.days - 2.months, shift_type_id: t1type.id)
        end
      end

      def create_t2andt3_shifts
        first_date = Shift.where(short_name: 'T1').order(:shift_date).first.shift_date
        t2type = FactoryGirl.create(:shift_type, short_name: 'T2')
        t3type = FactoryGirl.create(:shift_type, short_name: 'T3')
        (1..5).each do |n|
          FactoryGirl.create(:shift, shift_date: first_date + n.days + 1.month + 6.days, shift_type_id: t2type.id)
        end
        (6..10).each do |n|
          FactoryGirl.create(:shift, shift_date: first_date + n.days + 1.month + 6.days, shift_type_id: t3type.id)
        end
      end

      def select_rookie_training_shifts
        create_t1_shifts
        create_t2andt3_shifts
        t1 = Shift.where("short_name = 'T1'").first
        t2 = Shift.where("short_name = 'T2' and shift_date > '#{t1.shift_date}'").first
        t3 = Shift.where("short_name = 'T3' and shift_date > '#{t1.shift_date}'").first

        t1.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
        @rookie_user.shifts << t1
        t2.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
        t3.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
        @rookie_user.shifts << t2
        @rookie_user.shifts << t3
      end

      def create_late_season_tours
        start_date = rookie_tour_date
        (1..5).each do |n|
          FactoryGirl.create(:shift, shift_date: start_date + n.days, shift_type_id: @p1.id)
        end
      end

      def create_early_season_tours
        start_date = rookie_tour_date - 3.months
        (1..5).each do |n|
          FactoryGirl.create(:shift, shift_date: start_date + n.days, shift_type_id: @p1.id)
        end
      end

      def rookie_tour_date
        yr = Date.today.year + 1
        Date.parse("#{yr}-02-01")
      end

      def last_training_date
        @rookie_user.shifts.where("short_name not like 'M%'").map {|s| s.shift_date}.max
      end

      def select_all_shifts_user_can(user)
        Shift.all.each do |shift|
          if shift.can_select(user, HostUtility.can_select_params_for(user))
            user.shifts << shift
          end
        end
      end

      it "should not allow T2 or T3 to be picked prior to selected T1 shift" do
        t1type = FactoryGirl.create(:shift_type, short_name: 'T1')
        t1a = FactoryGirl.create(:shift, shift_date: Date.today + 6.days, shift_type_id: t1type.id)
        t1b = FactoryGirl.create(:shift, shift_date: Date.today + 7.days, shift_type_id: t1type.id)

        t1a.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
        t1b.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
        @rookie_user.shifts << t1b

        t1a.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      end

      # it "should not allow any other shifts selectable if T1 shift dropped" do
      def test_work
        create_t1_shifts
        create_t2andt3_shifts
        #
        # puts Shift.all.map {|s| [s.shift_date, s.short_name]}
        # puts "-------------"
        #
        # puts "today: #{Date.today}  Time: #{Time.now}  bingo: #{HostConfig.bingo_start_date}"
        #
        t1shift, t2shift, t3shift = nil
        Shift.where(short_name: "T1").order(:shift_date).each do |shift|
          shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          t1shift ||= shift
        end
        Shift.where("short_name in ('T2', 'T3')").order(:shift_date).each do |shift|
          shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          t2shift = shift if shift.short_name == 'T2'
          t3shift = shift if shift.short_name == 'T3'
        end
        @rookie_user.shifts << t1shift
        @rookie_user.shifts << t2shift
        @rookie_user.shifts << t3shift
        t1shift.user_id = nil
        t1shift.save
        @rookie_user.shifts.reload
        FactoryGirl.create(:shift, shift_date: Date.today + 100.days, shift_type_id: t1shift.shift_type_id)
        lowest_date = t3shift.shift_date < t2shift.shift_date ? t3shift.shift_date : t2shift.shift_date
        Shift.all.each do |shift|
          if shift.short_name == 'T1'
            if shift.shift_date < lowest_date
              shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
            else
              shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
            end
          else
            shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          end
        end
      end

      it "should not allow T2 shift to be picked before T1 shift" do
        select_rookie_training_shifts
        working_shifts = @rookie_user.trainings
        t1shift, t2shift, t3shift = nil
        working_shifts.each do |s|
          t1shift = s if s.short_name == "T1"
          t2shift = s if s.short_name == "T2"
        end

        t2shift.user_id = nil
        t2shift.save

        @rookie_user.shifts.reload
        new_t2 = FactoryGirl.create(:shift, shift_date: t1shift.shift_date - 10.days,
                                    shift_type_id: t2shift.shift_type_id)
        new_t2.can_select(@rookie_user,
                          HostUtility.can_select_params_for(@rookie_user)).must_equal false

        # if t2shift.can_select(@rookie_user,
        #                       HostUtility.can_select_params_for(@rookie_user)) == false
        #   puts t2shift.inspect
        # end

        t2shift.can_select(@rookie_user,
                           HostUtility.can_select_params_for(@rookie_user)).must_equal true
      end

      it "should not allow rookies to pick tour shifts before Feb 1" do
        select_rookie_training_shifts
        create_early_season_tours
        create_late_season_tours

        @tour_shifts.each do |shift|
          if shift.shift_date < rookie_tour_date
            shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          else
            shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          end
        end
      end

      it "should not allow rookies to pick p2 team leader shifts ever..." do
        p2weekday = FactoryGirl.create(:shift_type, short_name: 'P2weekday')
        start_date = rookie_tour_date
        (1..5).each do |n|
          s = FactoryGirl.create(:shift, shift_date: start_date + n.days, shift_type_id: p2weekday.id)
          s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end
      end

      it "should require first shift selected be T1" do
        Shift.all.each do |shift|
          shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end
        create_t1_shifts
        Shift.where(short_name: "T1").each do |shift|
          shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
        end
        create_t2andt3_shifts
        Shift.where("short_name in ('T2', 'T3')").each do |shift|
          shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end
      end

      it "should require second and third shifts selected be T2 and T3 (in any order)" do
        create_t1_shifts
        create_t2andt3_shifts
        t1shift = Shift.where(short_name: "T1").order(:shift_date).first
        @rookie_user.shifts << t1shift
        Shift.where("short_name in ('T1', 'T2', 'T3') and user_id is null").each do |shift|
          if shift.short_name == 'T1'
            shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          else
            if shift.shift_date < t1shift.shift_date
              shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
            else
              shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
            end
          end
        end
      end

      it "should not allow selecting anything but T2 or T3 before training shifts are selected" do
        create_t1_shifts
        create_t2andt3_shifts
        t1shift = Shift.where("short_name = 'T1'").first
        @rookie_user.shifts << t1shift
        Shift.all.each do |shift|
          if (shift.short_name == 'T2') || (shift.short_name == 'T3')
            if t1shift.shift_date < shift.shift_date
              shift.can_select(@rookie_user,
                           HostUtility.can_select_params_for(@rookie_user)).must_equal true
            else
              shift.can_select(@rookie_user,
                               HostUtility.can_select_params_for(@rookie_user)).must_equal false
            end
          else
            shift.can_select(@rookie_user,
                             HostUtility.can_select_params_for(@rookie_user)).must_equal false
          end
        end
      end

      it "should not allow multiple T2 or T3 shifts to be selected" do
        create_t1_shifts
        create_t2andt3_shifts
        @rookie_user.shifts << Shift.where(short_name: "T1").first
        @rookie_user.shifts << Shift.where(short_name: "T2").first
        @rookie_user.shifts << Shift.where(short_name: "T3").first
        Shift.where("short_name in ('T1', 'T2', 'T3') and user_id is null").each do |shift|
          shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end
      end

      it "should allow rookies to select non-tour shifts after training" do
        select_rookie_training_shifts
        allowed_shifts_after_date = last_training_date
        Shift.all.each do |shift|
          if shift.shift_date <= allowed_shifts_after_date
            shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          else
            shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true if shift.user_id.nil? && !shift.training? && !shift.is_tour? && !shift.team_leader?
          end
        end
      end

      describe "round tests" do
        it "should only allow 3 shifts to be selected prior to bingo starting" do
          @sys_config.bingo_start_date = @pre_bingo_date
          @sys_config.save!
          select_rookie_training_shifts
          select_all_shifts_user_can(@rookie_user)
          @rookie_user.shifts.count.must_equal 7
        end

        it "should only allow 8 shifts in round 1" do
          @sys_config.bingo_start_date = @round1_date - 2.days
          @sys_config.save!
          select_rookie_training_shifts
          select_all_shifts_user_can(@rookie_user)
          @rookie_user.shifts.count.must_equal 12
        end

        it "should only allow 13 shifts in round 2" do
          @sys_config.bingo_start_date = @round2_date - 2.days
          @sys_config.save!
          select_rookie_training_shifts
          select_all_shifts_user_can(@rookie_user)
          @rookie_user.shifts.count.must_equal 17
        end

        it "should only allow 16 shifts in round 3" do
          @sys_config.bingo_start_date = @round3_date - 2.days
          @sys_config.save!
          select_rookie_training_shifts
          select_all_shifts_user_can(@rookie_user)
          @rookie_user.shifts.count.must_equal 20
        end

        it "should be able to select more than 20 after bingo is over" do
          @sys_config.bingo_start_date = @round4_date - 15.days
          @sys_config.save!
          select_rookie_training_shifts
          select_all_shifts_user_can(@rookie_user)
          (@rookie_user.shifts.count > 20).must_equal true
        end
      end
    end
  end
end
