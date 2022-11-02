# == Schema Information
#
# Table name: shifts
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  shift_type_id   :integer          not null
#  shift_status_id :integer          default(1), not null
#  shift_date      :date
#  day_of_week     :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  short_name      :string
#  disabled        :boolean
#

require "test_helper"


class ShiftTest < ActiveSupport::TestCase
  def setup_vars
    @sys_config = SysConfig.first

    @rookie_user = User.find_by_name('rookie')
    @newer_user = User.find_by_name('g3')
    @middle_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g1')
    @team_leader = User.find_by_name('teamlead')
    @trainer = User.find_by_name('trainer')
    @driver = User.find_by_name('driver')

    @tl = ShiftType.find_by_short_name('TL')

    @p1end = ShiftType.find_by_short_name('P1weekend')
    @p2end = ShiftType.find_by_short_name('P2weekend')
    @p3end = ShiftType.find_by_short_name('P3weekend')
    @p4end = ShiftType.find_by_short_name('P4weekend')

    @g1end = ShiftType.find_by_short_name('G1weekend')
    @g2end = ShiftType.find_by_short_name('G2weekend')
    @g3end = ShiftType.find_by_short_name('G3weekend')
    @g4end = ShiftType.find_by_short_name('G4weekend')

    @c1end = ShiftType.find_by_short_name('C1weekend')
    @c2end = ShiftType.find_by_short_name('C2weekend')

    @h1end = ShiftType.find_by_short_name('H1weekend')
    @h2end = ShiftType.find_by_short_name('H2weekend')
    @h3end = ShiftType.find_by_short_name('H3weekend')
    @h4end = ShiftType.find_by_short_name('H4weekend')

    @p1day = ShiftType.find_by_short_name('P1weekday')
    @p2day = ShiftType.find_by_short_name('P2weekday')
    @p3day = ShiftType.find_by_short_name('P3weekday')
    @p4day = ShiftType.find_by_short_name('P4weekday')

    @g1day = ShiftType.find_by_short_name('G1weekday')
    @g2day = ShiftType.find_by_short_name('G2weekday')
    @g3day = ShiftType.find_by_short_name('G3weekday')

    @h1day = ShiftType.find_by_short_name('H1weekday')
    @h2day = ShiftType.find_by_short_name('H2weekday')

    # rookie training shifts
    @t1 = ShiftType.find_by_short_name('T1')

    # rookie trainER shift
    @tr = ShiftType.find_by(short_name: "TR")

    @regular_shift_types = [
      @p1end, @p2end, @p3end, @p4end, @g1end, @g2end, @g3end, @g4end,
      @c1end, @c2end, @h1end, @h2end, @h3end, @h4end, @p1day, @p2day,
      @p3day, @p4day, @g1day, @g2day, @g3day, @h1day, @h2day
    ]

    Timecop.freeze(Date.parse("2022-10-01"))
    @start_date = (Date.today() + 20.days)

    @pre_bingo_date = Date.today() + 1.day
    @round1_sr_date = Date.today()

    @round1_date = Date.today()
    @round2_date = Date.today() - 3.days
    @round3_date = Date.today() - 6.days
    @round4_date = Date.today() - 9.days
    @after_bingo_date = Date.today - 12.day
  end

  # def setup_vars_for_rookies
  #   setup_vars
  #
  #   # populate and select training shifts
  #
  #   @rookie_user.shifts << FactoryBot.create(:shift, shift_date: @round1_date + 20.day, shift_type_id: @t1.id)
  #   @rookie_user.shifts << FactoryBot.create(:shift, shift_date: @round1_date + 22.day, shift_type_id: @t1.id)
  #   @rookie_user.shifts << FactoryBot.create(:shift, shift_date: @round1_date + 24.day, shift_type_id: @t1.id)
  #   @rookie_user.shifts << FactoryBot.create(:shift, shift_date: @round1_date + 26.day, shift_type_id: @t1.id)
  #
  #   @last_training_date = @round1_date + 26.day
  #
  #   # setup regular shifts for selection
  #   dt_index = 0
  #   for dt in @after_bingo_date + 10.days..(@after_bingo_date + 25.days)
  #     @regular_shift_types.each do |st|
  #       shift = FactoryBot.create(:shift, shift_date: dt, shift_type_id: st.id)
  #     end
  #   end
  #   @pre_allowed_tour = FactoryBot.create(:shift, shift_date: ROOKIE_TOUR_DATE - 5.days, shift_type_id: @p1end.id)
  #   @allowed_tour = FactoryBot.create(:shift, shift_date: ROOKIE_TOUR_DATE, shift_type_id: @p1end.id)
  # end

  def run_bingo_shift_max_pick(bingo_start_date, user, round_number, max_number_shifts)
    @sys_config.bingo_start_date = bingo_start_date
    @sys_config.save!

    Shift.all.each do |s|
      next if (s.team_leader?) || user.is_working?(s.shift_date) || s.meeting? || s.training? || s.trainer? || s.is_tour?

      can_select = s.can_select(user, HostUtility.can_select_params_for(user))
      if user.shifts.count < max_number_shifts
        can_select.must_equal true
        user.shifts << s
      else
        can_select.must_equal false
      end
    end
  end

  def run_bingo_tour_shift_max_pick(bingo_start_date, user, round_number, max_number_shifts)
    @sys_config.bingo_start_date = bingo_start_date
    @sys_config.save!

    Shift.all.each do |s|
      next if !s.is_tour? || user.is_working?(s.shift_date)

      can_select = s.can_select(user, HostUtility.can_select_params_for(user))
      if user.shifts.count < max_number_shifts
        can_select.must_equal true
        user.shifts << s
      else
        can_select.must_equal false
      end
    end
  end

  def run_cannot_pick_selected_shifts(bingo_start_date, selected_user, user)
    @sys_config.bingo_start_date = bingo_start_date
    @sys_config.save!

    @regular_shift_types.each do |st|
      shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: st.id)
      shift.user_id = selected_user.id
      shift.save!
      shift.can_select(user, HostUtility.can_select_params_for(user)).must_equal false
    end
  end

  def run_cannot_pick_disabled_shifts(bingo_start_date, user)
    @sys_config.bingo_start_date = bingo_start_date
    @sys_config.save!
    shift = FactoryBot.create(:shift, shift_date: Date.today + 25.days, shift_type_id: @regular_shift_types[0].id)
    shift.can_select(user, HostUtility.can_select_params_for(user)).must_equal true

    shift.disabled = true
    shift.save!
    shift.can_select(user, HostUtility.can_select_params_for(user)).must_equal false
  end

  def run_cannot_pick_working_days(bingo_start_date, user)
    @sys_config.bingo_start_date = @after_bingo_date
    @sys_config.save!

    shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days,
                              shift_type_id: @regular_shift_types[0].id)

    working_shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days,
                                      shift_type_id: @regular_shift_types[1].id)
    user.shifts << working_shift
    shift.can_select(user, HostUtility.can_select_params_for(user)).must_equal false
  end

  after do
    Timecop.return
  end

  describe 'can_drop' do
    it 'cannot drop shifts within two week limit' do
      setup_vars

      # set bingo to start 6 rounds ago so we're well past bingo time
      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 6)
      @sys_config.save!

      # create 4 shifts and select by  hosts (shift date 1 week out)
      @rookieshift = FactoryBot.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p1end.id, :user_id => @rookie_user.id)
      @g1shift = FactoryBot.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p1end.id, :user_id => @newer_user.id)
      @g2shift = FactoryBot.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p2end.id, :user_id => @middle_user.id)
      @g3shift = FactoryBot.create(:shift, :shift_date => Date.today + 1.week, :shift_type_id => @p3end.id, :user_id => @senior_user.id)

      # can not drop any shifts
      @rookieshift.can_drop(@rookie_user).must_equal false
      @g1shift.can_drop(@newer_user).must_equal false
      @g2shift.can_drop(@middle_user).must_equal false
      @g3shift.can_drop(@senior_user).must_equal false

      # cannot drop OGOMTraining shifts
      @ogomt_shift_date = FactoryBot.create(:training_date, shift_date: Date.today + 1.week)
      @ogomt_shift1 = FactoryBot.create(:ongoing_training, training_date_id: @ogomt_shift_date.id, user_id: @newer_user.id)
      @ogomt_shift2 = FactoryBot.create(:ongoing_training, training_date_id: @ogomt_shift_date.id, user_id: @middle_user.id)
      @ogomt_shift3 = FactoryBot.create(:ongoing_training, training_date_id: @ogomt_shift_date.id, user_id: @senior_user.id)

      _(@ogomt_shift1.can_drop(@newer_user)).must_equal false
      _(@ogomt_shift2.can_drop(@middle_user)).must_equal false
      _(@ogomt_shift3.can_drop(@senior_user)).must_equal false
    end

    it 'can drop any shifts outside of 2 week window' do
      setup_vars

      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 6)
      @sys_config.save!

      # create 4 other shifts and select by other hosts (shift date 3 weeks out)
      @g1shift = FactoryBot.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p1end.id, :user_id => @newer_user.id)
      @g2shift = FactoryBot.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p2end.id, :user_id => @middle_user.id)
      @g3shift = FactoryBot.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p3end.id, :user_id => @senior_user.id)
      @g4shift = FactoryBot.create(:shift, :shift_date => Date.today + 3.week, :shift_type_id => @p3end.id, :user_id => @rookie_user.id)

      # can  drop any shifts
      @g1shift.can_drop(@newer_user).must_equal true
      @g2shift.can_drop(@middle_user).must_equal true
      @g3shift.can_drop(@senior_user).must_equal true
      @g4shift.can_drop(@rookie_user).must_equal true

      # TODO - add team leader and trainer and trainee logic to can drop

      # TODO ogomt can drop
      # @ogomt_shift_date = FactoryBot.create(:training_date, shift_date: Date.today + 3.weeks)
      # @ogomt_shift1 = FactoryBot.create(:ongoing_training, training_date_id: @ogomt_shift_date.id, user_id: @newer_user.id)
      # @ogomt_shift2 = FactoryBot.create(:ongoing_training, training_date_id: @ogomt_shift_date.id, user_id: @middle_user.id)
      # @ogomt_shift3 = FactoryBot.create(:ongoing_training, training_date_id: @ogomt_shift_date.id, user_id: @senior_user.id)
      #
      # @ogomt_shift1.can_drop(@newer_user).must_equal true
      # @ogomt_shift2.can_drop(@middle_user).must_equal true
      # @ogomt_shift3.can_drop(@senior_user).must_equal true
    end
  end

  describe 'can_select' do

    describe 'team leaders' do
      before do
        setup_vars
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

      it 'must have 12 shifts after setup' do
        @team_leader.shifts.count.must_equal 12
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

      it "can select any shifts other than rookie" do
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

      it "cannot select more than 20 shifts during round 1 bingo" do
        @sys_config.bingo_start_date = @round1_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 1

        Shift.all.each do |s|
          next if s.meeting? || s.is_tour?

          if (!@team_leader.is_working?(s.shift_date) && !s.trainer? && !s.training? && !s.survey? && @team_leader.shifts.count < 20)
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal true
            @team_leader.shifts << s
          else
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
          end
        end
        (@team_leader.shifts.count == 20).must_equal true

        new_tl_shift = FactoryBot.create(:shift, shift_type_id: @tl.id, shift_date: @team_leader.shifts.map(&:shift_date).max + 1.day)
        new_tl_shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false

        new_shift = FactoryBot.create(:shift, shift_type_id: @p1end.id, shift_date: @team_leader.shifts.map(&:shift_date).max + 1.day)
        new_shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
      end

      it "cannot select more than 20 shifts during round 4 bingo" do
        @sys_config.bingo_start_date = @round4_date
        @sys_config.save!
        HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 4

        Shift.all.each do |s|
          next if s.meeting? || s.is_tour?

          if (!@team_leader.is_working?(s.shift_date) && !s.trainer? && !s.training? && !s.survey? && @team_leader.shifts.count < 20)
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal true
            @team_leader.shifts << s
          else
            s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
          end
        end
        (@team_leader.shifts.count == 20).must_equal true

        new_tl_shift = FactoryBot.create(:shift, shift_type_id: @tl.id, shift_date: @team_leader.shifts.map(&:shift_date).max + 1.day)
        new_tl_shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false

        new_shift = FactoryBot.create(:shift, shift_type_id: @p1end.id, shift_date: @team_leader.shifts.map(&:shift_date).max + 1.day)
        new_shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
      end

      it "cannot select training or trainer shifts" do
        @sys_config.bingo_start_date = @round4_date
        @sys_config.save!
        round = HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @team_leader).must_equal 4

        # create trainer and training shifts
        @tr = ShiftType.find_by(short_name: 'TR')
        t1type = FactoryBot.create(:shift_type, short_name: 'T1')
        t2type = FactoryBot.create(:shift_type, short_name: 'T2')
        t3type = FactoryBot.create(:shift_type, short_name: 'T3')
        training_shifts = []
        (1..5).each do |n|
          trainer_shift = FactoryBot.create(:shift, :shift_date => Date.today + 2.weeks + n.days,
                                            :shift_type_id => @tr.id, :user_id => nil)
          t1_shift = FactoryBot.create(:shift, shift_date: Date.today + n.days, shift_type_id: t1type.id)
          t2_shift = FactoryBot.create(:shift, shift_date: Date.today + n.days, shift_type_id: t2type.id)
          t3_shift = FactoryBot.create(:shift, shift_date: Date.today + n.days, shift_type_id: t3type.id)
          training_shifts << trainer_shift
          training_shifts << t1_shift
          training_shifts << t2_shift
          training_shifts << t3_shift
        end

        training_shifts.each do |s|
          s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal false
        end
      end

      it 'can pick any regular shifts after bingo' do
        @sys_config.bingo_start_date = @round4_date
        @sys_config.save!

        Shift.all.each do |s|
          if s.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)) == true
            @team_leader.shifts << s
          end
        end
        @team_leader.shifts.count.must_equal 20

        @sys_config.bingo_start_date = @after_bingo_date
        @sys_config.save!

        @regular_shift_types.each do |st|
          shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: st.id)
          shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal true
        end
      end
    end

    # describe 'trainers' do
    #   before do
    #     setup_vars
    #     shift = FactoryBot.create(:shift, shift_date: @round1_date + 20.day, shift_type_id: @tr.id)
    #     shift = FactoryBot.create(:shift, shift_date: @round1_date + 21.day, shift_type_id: @tr.id)
    #     shift = FactoryBot.create(:shift, shift_date: @round1_date + 22.day, shift_type_id: @tr.id)
    #     shift = FactoryBot.create(:shift, shift_date: @round1_date + 20.day, shift_type_id: @tr.id)
    #   end
    #
    #   it 'can pick trainer shifts before bingo' do
    #     @sys_config.bingo_start_date = @pre_bingo_date
    #     @sys_config.save!
    #     Shift.all.each do |s|
    #       if s.can_select(@trainer, HostUtility.can_select_params_for(@trainer))
    #         @trainer.shifts << s if s.short_name == "TR"
    #         break if @trainer.shifts.count >= 20
    #       else
    #         s.short_name.wont_equal "TR"
    #       end
    #     end
    #
    #   end
    #     # TODO: get this shit working!
    #     #
    #   # trainer can pick trainer shifts prior to bingo
    #
    #   # create 5 @tr shifts and pick them prior to bingo
    #   # create 6 @tr shifts and pick them.. can pick 5 shifts in rounds 1,2 and 4 in 3
    #
    # end

    describe 'before bingo' do
      describe 'non-rookies' do
        it 'cannot select any shifts' do
          setup_vars
          @sys_config.bingo_start_date = @pre_bingo_date
          @sys_config.save!

          # confirm round setting is correct
          HostUtility.get_current_round(@sys_config.bingo_start_date, Date.today, @senior_user).must_equal 0

          Shift.all.each do |s|
            s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
            s.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false
            s.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false
          end
        end
      end

      describe 'rookies' do
        before do
          @training_shifts = Shift.where(short_name: 'T1')
          @starting_date = @training_shifts.first.shift_date
        end

        # focus
        it 'can pick training shift in week 1' do
          setup_vars
          # first week @starting_date  shift 1
          t1_shift = @training_shifts.first

          t1_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          @rookie_user.shifts << t1_shift
          t2_shift = @training_shifts.second
          t2_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        # focus
        it 'can pick training shift in week 2' do
          setup_vars
          # select first shift in week 1
          t1_shift = @training_shifts.first
          @rookie_user.shifts << t1_shift

          # second week @starting_date + 7.days  shift 1
          t2_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).first
          t3_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).second
          t2_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          t3_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          @rookie_user.shifts << t3_shift
          t2_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @training_shifts.second.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        # focus
        it 'can pick training shift in week 3' do
          setup_vars
          t1_shift = @training_shifts.first
          @rookie_user.shifts << t1_shift
          t2_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).first
          @rookie_user.shifts << t2_shift

          t2b_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2 + 1.day).first
          t2b_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false

          # third week @starting_date + 14.days  shift 1
          t3_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK3).first
          t4_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK3).second
          t3_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          t4_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          @rookie_user.shifts << t3_shift
          t4_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @training_shifts.second.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).second.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        it 'can pick regular shifts in week 4 and 5' do
          setup_vars
          t1_shift = @training_shifts.first
          @rookie_user.shifts << t1_shift
          t2_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).first
          @rookie_user.shifts << t2_shift
          t3_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK3).first
          @rookie_user.shifts << t3_shift

          # cannot pick training shift in week 4 or 5 or 6
          t4_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK4).first
          t5_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK5).first
          t6_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK6).first

          t4_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          t5_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          t6_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false

          # can pick regular shift in week 4 and 5
          shift4 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK4,
                                    shift_type_id: @regular_shift_types[0].id)
          shift5 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5,
                                    shift_type_id: @regular_shift_types[0].id)
          shift4.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          shift5.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          @rookie_user.shifts << shift4
          shift5.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          @rookie_user.shifts << shift5

          shift6 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5 + 4.days,
                                     shift_type_id: @regular_shift_types[0].id)

          shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false

          shift7 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5 + 2.weeks,
                                     shift_type_id: @regular_shift_types[0].id)
          shift7.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        it 'can pick training shift in week 6' do
          setup_vars
          t1_shift = @training_shifts.first
          @rookie_user.shifts << t1_shift
          t2_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).first
          @rookie_user.shifts << t2_shift
          t3_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK3).first
          @rookie_user.shifts << t3_shift
          shift4 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK4,
                                     shift_type_id: @regular_shift_types[0].id)
          shift5 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5,
                                     shift_type_id: @regular_shift_types[0].id)
          @rookie_user.shifts << shift4
          @rookie_user.shifts << shift5

          t4_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK6).first
          t4_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true

          t5_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK6 + 1.day).first
          t5_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true

          t3b_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK3 + 1.day).first
          t3b_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @rookie_user.shifts << t4_shift
          t5_shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        it 'no training picked, can only see week 1' do
          setup_vars
          regular_shift1 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK1,
                                     shift_type_id: @regular_shift_types[0].id)
          regular_shift2 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK2,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift3 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK3,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift4 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK4,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift5 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift6 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_END + 1.day,
                                             shift_type_id: @regular_shift_types[0].id)
          training_shift1 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK1,
                                             shift_type_id: @t1.id)
          training_shift2 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK2,
                                              shift_type_id: @t1.id)
          regular_shift1.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          regular_shift2.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          regular_shift3.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          regular_shift4.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          regular_shift5.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          regular_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          training_shift1.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          training_shift2.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        it 'can not pick regular shifts prior to training shift 3 for week 4 and 5 ' do
          setup_vars
          t1_shift = @training_shifts.first
          @rookie_user.shifts << t1_shift
          t2_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).first
          @rookie_user.shifts << t2_shift
          t3_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK3).first
          @rookie_user.shifts << t3_shift

          badshift = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK3 + 1.day,
                                       shift_type_id: @regular_shift_types[0].id)
          badshift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false

          badshift2 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_END + 1.day,
                                       shift_type_id: @regular_shift_types[0].id)
          badshift2.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        it 'can not pick regular shifts after picking regs in week 4 and 5' do
          setup_vars
          t1_shift = @training_shifts.first
          @rookie_user.shifts << t1_shift
          t2_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK2).first
          @rookie_user.shifts << t2_shift
          t3_shift = @training_shifts.where(shift_date: Shift::ROOKIE_TRAINING_WEEK3).first
          @rookie_user.shifts << t3_shift

          reg_shift1 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK4,
                                      shift_type_id: @regular_shift_types[0].id)
          reg_shift2 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5,
                                         shift_type_id: @regular_shift_types[0].id)
          @rookie_user.shifts << reg_shift1
          @rookie_user.shifts << reg_shift2

          badshift = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK3 + 1.day,
                                       shift_type_id: @regular_shift_types[0].id)
          @rookie_user.shifts.count.must_equal 8
          badshift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        it 'can only see training shifts for week you are picking' do
          setup_vars
          training_shift1 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK1,
                                              shift_type_id: @t1.id)
          training_shift2 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK2,
                                              shift_type_id: @t1.id)
          training_shift3 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK3,
                                              shift_type_id: @t1.id)
          training_shift6 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK6,
                                              shift_type_id: @t1.id)
          regular_shift4 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK4,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift5 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift6 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK6,
                                             shift_type_id: @regular_shift_types[0].id)

          training_shift1.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          training_shift2.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @rookie_user.shifts << training_shift1
          training_shift2.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          training_shift3.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @rookie_user.shifts << training_shift2
          training_shift3.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          training_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @rookie_user.shifts << training_shift3
          training_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @rookie_user.shifts << regular_shift4

          regular_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          training_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
          @rookie_user.shifts << regular_shift5

          training_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
          regular_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end

        it 'cannot pick shifts after training quota reached until round 1' do
          setup_vars
          training_shift1 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK1,
                                              shift_type_id: @t1.id)
          training_shift2 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK2,
                                              shift_type_id: @t1.id)
          training_shift3 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK3,
                                              shift_type_id: @t1.id)
          training_shift6 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK6,
                                              shift_type_id: @t1.id)
          regular_shift4 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK4,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift5 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_WEEK5,
                                             shift_type_id: @regular_shift_types[0].id)
          regular_shift6 = FactoryBot.create(:shift, shift_date: Shift::ROOKIE_TRAINING_END + 2.day,
                                             shift_type_id: @regular_shift_types[0].id)

          @rookie_user.shifts << training_shift1
          @rookie_user.shifts << training_shift2
          @rookie_user.shifts << training_shift3
          @rookie_user.shifts << regular_shift4
          @rookie_user.shifts << regular_shift5
          @rookie_user.shifts << training_shift6

          regular_shift6.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
        end
      end
    end

    describe 'after bingo' do
      # describe 'rookies' do
      #
      #   it "can select after bingo - rookies" do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @after_bingo_date - 7.days
      #     @sys_config.save!
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 8
      #
      #     training_shifts = []
      #     @rookie_user.shifts.each do |s|
      #       training_shifts << s if s.training?
      #     end
      #     training_shifts.count.must_equal 4
      #
      #     # pick all 20 shifts
      #     Shift.all.each do |s|
      #       break if @rookie_user.shifts.count >= 20
      #
      #       if s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)) == true
      #         @rookie_user.shifts << s
      #       end
      #     end
      #     @rookie_user.shifts.count.must_equal 20
      #
      #     Shift.all.each do |s|
      #       # skip working, meeting, disabled, staffed
      #       next if @rookie_user.is_working?(s.shift_date) || s.meeting? || s.disabled? || !s.user_id.nil? || s.team_leader?
      #       if s.training? || s.team_leader?
      #         s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #       end
      #
      #       if s.shift_date <= @last_training_date
      #         s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #       end
      #
      #       if s.is_tour?
      #         if s.shift_date < ROOKIE_TOUR_DATE
      #           s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #         else
      #           s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #         end
      #       else
      #         s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #       end
      #     end
      #     s = FactoryBot.create(:shift, shift_date: @round1_date + 25.day, shift_type_id: @p1end.id)
      #     (s.shift_date < @last_training_date).must_equal true
      #     s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it "after bingo - rookies: cannot pick any selected shift" do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @after_bingo_date - 7.days
      #     @sys_config.save!
      #
      #     @regular_shift_types.each do |st|
      #       shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: st.id)
      #       shift.user_id = @senior_user.id
      #       shift.save!
      #       shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #     end
      #   end
      #
      #   it 'after bingo - rookies: cannot pick teamleader if not teamleader' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @after_bingo_date - 7.days
      #     @sys_config.save!
      #
      #     # is not team leader
      #     shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: @tl.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #
      #     # is team leader
      #     shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal true
      #   end
      #
      #   it 'after bingo - rookies: cannot pick if shift is disabled' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 5) - 8.days
      #     @sys_config.save!
      #
      #     shift = FactoryBot.create(:shift, shift_date: Date.today + 30.days, shift_type_id: @g1end.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #
      #     shift.disabled = true
      #     shift.save!
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   # can't pick if not admin - and shift is prior to today
      #   it 'after bingo - rookies: cannot pick if shift is prior to today' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @after_bingo_date - 7.days
      #     @sys_config.save!
      #     shift = FactoryBot.create(:shift, shift_date: Date.today - 1.days, shift_type_id: @regular_shift_types[0].id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   # can't pick if already working that day
      #   it 'after bingo - rookies: cannot pick if already working that day' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @after_bingo_date - 7.days
      #     @sys_config.save!
      #
      #     shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days,
      #                               shift_type_id: @regular_shift_types[0].id)
      #
      #     working_shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days,
      #                                       shift_type_id: @regular_shift_types[1].id)
      #     @rookie_user.shifts << working_shift
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      # end

      describe 'non-rookies' do
        it "after bingo - non-rookies: can pick any shifts not selected" do
          setup_vars
          @sys_config.bingo_start_date = @after_bingo_date - 7.days
          @sys_config.save!

          @regular_shift_types.each do |st|
            shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: st.id)
            shift.user_id.must_be_nil
            shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal true
          end
        end

        it "after bingo - non-rookies: cannot pick any selected shift" do
          setup_vars
          @sys_config.bingo_start_date = @after_bingo_date - 7.days
          @sys_config.save!

          @regular_shift_types.each do |st|
            shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: st.id)
            shift.user_id = @middle_user.id
            shift.save!
            shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
          end
        end

        it 'after bingo - non-rookies: cannot pick teamleader if not teamleader' do
          setup_vars
          @sys_config.bingo_start_date = @after_bingo_date - 7.days
          @sys_config.save!

          # is not team leader
          shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: @tl.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false

          # is team leader
          shift.can_select(@team_leader, HostUtility.can_select_params_for(@team_leader)).must_equal true
        end

        # can't pick if disabled
        it 'after bingo - non-rookies: cannot pick if shift is disabled' do
          setup_vars
          @sys_config.bingo_start_date = @after_bingo_date - 7.days
          @sys_config.save!
          shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days, shift_type_id: @regular_shift_types[0].id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal true

          shift.disabled = true
          shift.save!
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end

        # can't pick if not admin - and shift is prior to today
        it 'after bingo - non-rookies: cannot pick if shift is prior to today' do
          setup_vars
          @sys_config.bingo_start_date = @after_bingo_date - 7.days
          @sys_config.save!
          shift = FactoryBot.create(:shift, shift_date: Date.today - 1.days, shift_type_id: @regular_shift_types[0].id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end

        # can't pick if already working that day
        it 'after bingo - non-rookies: cannot pick if already working that day' do
          setup_vars
          @sys_config.bingo_start_date = @after_bingo_date - 7.days
          @sys_config.save!

          shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days,
                                    shift_type_id: @regular_shift_types[0].id)

          working_shift = FactoryBot.create(:shift, shift_date: Date.today + 5.days,
                                            shift_type_id: @regular_shift_types[1].id)
          @senior_user.shifts << working_shift
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end
      end
    end

    it 'cannot pick more than 7 tours during bingo' do
      setup_vars
      run_bingo_tour_shift_max_pick(@round1_sr_date, @senior_user, 1, 7)

      run_bingo_tour_shift_max_pick(@round2_date, @senior_user, 2, 9)

      shift = FactoryBot.create(:shift, shift_date: Date.today + 2.months, shift_type_id: @p1day.id)
      shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false

      @sys_config.bingo_start_date = @round4_date
      @sys_config.save!
      shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false

      @sys_config.bingo_start_date = @after_bingo_date
      @sys_config.save!
      shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal true
    end

    describe 'round 1' do
      describe 'senior' do
        # focus
        # it 'trainer shifts do not count against bingo' do
        #   false.must_equal true
        # end


        # focus
        # I verified in practice that this works.. but the test does not
        # it 'ogomt shifts do not count against bingo quota' do
        #   setup_vars
        #   run_bingo_shift_max_pick(@round1_sr_date, @senior_user, 1, 7)
        #
        #   dt = TrainingDate.create(shift_date: @round1_date + 20.days)
        #   training = OngoingTraining.create(training_date_id: dt.id)
        #
        #   @senior_user.can_select_ongoing_training(@round1_date + 20.days).must_equal true
        #   @senior_user.ongoing_trainings << training
        #
        #   dt = TrainingDate.create(shift_date: @round1_date + 21.days)
        #   training = OngoingTraining.create()
        #   @senior_user.can_select_ongoing_training(@round1_date + 21.days).must_equal false
        # end

        it 'senior - round 1 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round1_sr_date
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end

        it "senior - can pick up to 5 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round1_sr_date, @senior_user, 1, 7)
        end

        it "senior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round1_sr_date, @middle_user, @senior_user)
        end

        it 'senior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round1_sr_date, @senior_user)
        end

        it 'senior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round1_sr_date, @senior_user)
        end
      end

      describe 'junior' do
        it 'junior - round 1 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round1_date - 1.day
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false
        end

        it "junior- can pick up to 5 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round1_sr_date - 1.day, @middle_user, 1, 7)
        end

        it "junior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round1_sr_date - 1.day, @senior_user, @middle_user)
        end

        it 'junior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round1_sr_date - 1.day, @middle_user)
        end

        it 'junior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round1_sr_date - 1.day, @middle_user)
        end
      end

      describe 'freshman' do
        it 'freshman - round 1 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round1_sr_date - 2.day
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false
        end

        it "freshman - can pick up to 5 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round1_sr_date - 2.day, @newer_user, 1, 7)
        end

        it "freshman - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round1_sr_date - 2.day, @senior_user, @newer_user)
        end

        it 'freshman - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round1_sr_date - 2.day, @newer_user)
        end

        it 'freshman - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round1_sr_date - 2.day, @newer_user)
        end
      end

      # describe 'rookie' do
      #
      #   it 'round 1 - rookies: cannot pick shift before last training shift' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 1)
      #     @sys_config.save!
      #     shift = FactoryBot.create(:shift, shift_date: @round1_date + 25.days, shift_type_id: @g1end.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it 'round 1 - rookies: can pick 5 shifts, all after training dates, P shifts after 2/1' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round1_sr_date - 2.day
      #     @sys_config.save!
      #
      #     Shift.all.each do |s|
      #       next if (s.team_leader?) || @rookie_user.is_working?(s.shift_date) || s.meeting? || s.training? || s.trainer?
      #
      #       if s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)) == true
      #         @rookie_user.shifts << s
      #       end
      #     end
      #
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 13
      #
      #     @rookie_user.shifts.delete(@rookie_user.shifts[-1])
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 12
      #
      #     @allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #     @pre_allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it "round 1 - rookies:  - cannot pick any selected shift" do
      #     setup_vars_for_rookies
      #     run_cannot_pick_selected_shifts(@round1_sr_date - 2.day, @senior_user, @rookie_user)
      #   end
      #
      #   it 'round 1 - rookies:  - cannot pick if shift is disabled' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round1_sr_date - 2.day
      #     @sys_config.save!
      #
      #     shift = FactoryBot.create(:shift, shift_date: @last_training_date + 5.days, shift_type_id: @g1end.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #
      #     shift.disabled = true
      #     shift.save!
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it 'round 1 - rookies:  - cannot pick if already working that day' do
      #     setup_vars_for_rookies
      #     run_cannot_pick_working_days(@round1_sr_date - 2.day, @rookie_user)
      #   end
      # end
    end

    describe 'round 2' do
      describe 'senior' do
        it 'senior - round 2 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round2_date
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end


        it "senior - can pick up to 10 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round2_date, @senior_user, 2, 12)
        end

        it "senior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round2_date, @middle_user, @senior_user)
        end

        it 'senior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round2_date, @senior_user)
        end

        it 'senior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round2_date, @senior_user)
        end
      end

      describe 'junior' do
        it 'junior - round 2 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round2_date - 1.day
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false
        end

        it "junior - can pick up to 10 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round2_date - 1.day, @middle_user, 2, 12)
        end

        it "junior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round2_date - 1.day, @senior_user, @middle_user)
        end

        it 'junior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round2_date - 1.day, @middle_user)
        end

        it 'junior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round2_date - 1.day, @middle_user)
        end
      end

      describe 'freshman' do
        it 'freshman - round 2 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round2_date - 2.day
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false
        end

        it "freshman - can pick up to 10 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round2_date - 2.day, @newer_user, 2, 12)
        end

        it "freshman - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round2_date - 2.day, @senior_user, @newer_user)
        end

        it 'freshman - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round2_date - 2.day, @newer_user)
        end

        it 'freshman - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round2_date - 2.day, @newer_user)
        end
      end

      # describe 'rookie' do
      #   it 'round 2 - rookies: cannot pick shift before last training shift' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@rookie_user, 2)
      #     @sys_config.save!
      #     shift = FactoryBot.create(:shift, shift_date: @round1_date + 6.day, shift_type_id: @g1end.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #
      #   it 'round 2 - rookies: can pick 10 shifts, all after training dates, P shifts after 2/1' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round2_date - 2.day
      #     @sys_config.save!
      #
      #     Shift.all.each do |s|
      #       next if (s.team_leader?) || @rookie_user.is_working?(s.shift_date) || s.meeting? || s.training? || s.trainer?
      #
      #       if s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)) == true
      #         @rookie_user.shifts << s
      #       end
      #     end
      #
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 18
      #
      #     @rookie_user.shifts.delete(@rookie_user.shifts[-1])
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 17
      #
      #     @allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #     @pre_allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it "round 2 - rookies:  - cannot pick any selected shift" do
      #     setup_vars_for_rookies
      #     run_cannot_pick_selected_shifts(@round2_date - 2.day, @senior_user, @rookie_user)
      #   end
      #
      #   it 'round 2 - rookies:  - cannot pick if shift is disabled' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round2_date - 2.day
      #     @sys_config.save!
      #
      #     shift = FactoryBot.create(:shift, shift_date: @last_training_date + 5.days, shift_type_id: @g1end.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #
      #     shift.disabled = true
      #     shift.save!
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it 'round 2 - rookies:  - cannot pick if already working that day' do
      #     setup_vars_for_rookies
      #     run_cannot_pick_working_days(@round2_date - 2.day, @rookie_user)
      #   end
      # end
    end

    describe 'round 3' do
      describe 'senior' do
        it 'senior - round 3 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round3_date
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end

        it "senior - can pick up to 15 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round3_date, @senior_user, 3, 17)
        end

        it "senior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round3_date, @middle_user, @senior_user)
        end

        it 'senior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round3_date, @senior_user)
        end

        it 'senior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round3_date, @senior_user)
        end
      end

      describe 'junior' do
        it 'junior - round 3 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round3_date - 1.day
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false
        end

        it "junior - can pick up to 15 shifts" do
          setup_vars

          run_bingo_shift_max_pick(@round3_date - 1.day, @middle_user, 3, 17)
        end

        it "junior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round3_date - 1.day, @senior_user, @middle_user)
        end

        it 'junior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round3_date - 1.day, @middle_user)
        end

        it 'junior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round3_date - 1.day, @middle_user)
        end
      end

      describe 'freshman' do
        it 'freshman - round 3 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round3_date - 2.day
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false
        end

        it "freshman - can pick up to 15 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round3_date - 2.day, @newer_user, 3, 17)
        end

        it "freshman - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round3_date - 2.day, @senior_user, @newer_user)
        end

        it 'freshman - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round3_date - 2.day, @newer_user)
        end

        it 'freshman - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round3_date - 2.day, @newer_user)
        end
      end

      # describe 'rookie' do
      #   it 'round 3 - rookies: can pick 16 shifts, all after training dates, P shifts after 2/1' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round3_date - 2.day
      #     @sys_config.save!
      #
      #     Shift.all.each do |s|
      #       next if (s.team_leader?) || @rookie_user.is_working?(s.shift_date) || s.meeting? || s.training? || s.trainer?
      #
      #       if s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)) == true
      #         @rookie_user.shifts << s
      #       end
      #     end
      #
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 20
      #
      #     @rookie_user.shifts.delete(@rookie_user.shifts[-1])
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 19
      #
      #     @allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #     @pre_allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it "round 3 - rookies:  - cannot pick any selected shift" do
      #     setup_vars_for_rookies
      #     run_cannot_pick_selected_shifts(@round3_date - 2.day, @senior_user, @rookie_user)
      #   end
      #
      #   it 'round 3 - rookies:  - cannot pick if shift is disabled' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round3_date - 2.day
      #     @sys_config.save!
      #
      #     shift = FactoryBot.create(:shift, shift_date: @last_training_date + 5.days, shift_type_id: @g1end.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #
      #     shift.disabled = true
      #     shift.save!
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it 'round 3 - rookies:  - cannot pick if already working that day' do
      #     setup_vars_for_rookies
      #     run_cannot_pick_working_days(@round3_date - 2.day, @rookie_user)
      #   end
      # end
    end

    describe 'round 4' do
      describe 'senior' do
        it 'senior - round 4 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round4_date
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @senior_user.id)
          shift.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)).must_equal false
        end

        it "senior - can pick up to 18 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round4_date, @senior_user, 4, 20)
        end

        it "senior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round4_date, @middle_user, @senior_user)
        end

        it 'senior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round4_date, @senior_user)        end

        it 'senior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round4_date, @senior_user)
        end
      end

      describe 'junior' do
        it 'junior - round 4 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round4_date
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @middle_user.id)
          shift.can_select(@middle_user, HostUtility.can_select_params_for(@middle_user)).must_equal false
        end

        it "junior - can pick up to 18 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round4_date, @middle_user, 4, 20)
        end

        it "junior - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round4_date, @senior_user, @middle_user)
        end

        it 'junior - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round4_date, @middle_user)
        end

        it 'junior - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round4_date, @middle_user)
        end
      end

      describe 'freshman' do
        it 'freshman - round 4 - cannot pick training shifts' do
          setup_vars
          @sys_config.bingo_start_date = @round4_date
          @sys_config.save!

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @t1.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false

          shift = FactoryBot.create(:shift, :shift_date => Date.today + 9.weeks, :shift_type_id => @tr.id, :user_id => @newer_user.id)
          shift.can_select(@newer_user, HostUtility.can_select_params_for(@newer_user)).must_equal false
        end
        it "freshman - can pick up to 18 shifts" do
          setup_vars
          run_bingo_shift_max_pick(@round4_date, @newer_user, 4, 20)
        end

        it "freshman - cannot pick any selected shift" do
          setup_vars
          run_cannot_pick_selected_shifts(@round4_date, @senior_user, @newer_user)
        end

        it 'freshman - cannot pick if shift is disabled' do
          setup_vars
          run_cannot_pick_disabled_shifts(@round4_date, @newer_user)
        end

        it 'freshman - cannot pick if already working that day' do
          setup_vars
          run_cannot_pick_working_days(@round4_date, @newer_user)
        end
      end

      # describe 'rookie' do
      #   it 'round 4 - rookies: can pick 16 shifts, all after training dates, P shifts after 2/1' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round4_date
      #     @sys_config.save!
      #
      #     Shift.all.each do |s|
      #       next if (s.team_leader?) || @rookie_user.is_working?(s.shift_date) || s.meeting? || s.training? || s.trainer?
      #
      #       if s.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)) == true
      #         @rookie_user.shifts << s
      #       end
      #     end
      #
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 20
      #
      #     @rookie_user.shifts.delete(@rookie_user.shifts[-1])
      #     @rookie_user.shifts.map(&:short_name).count.must_equal 19
      #
      #     @allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #     @pre_allowed_tour.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it "round 4 - rookies:  - cannot pick any selected shift" do
      #     setup_vars_for_rookies
      #     run_cannot_pick_selected_shifts(@round4_date, @senior_user, @rookie_user)
      #   end
      #
      #   it 'round 4 - rookies:  - cannot pick if shift is disabled' do
      #     setup_vars_for_rookies
      #     @sys_config.bingo_start_date = @round4_date
      #     @sys_config.save!
      #
      #     shift = FactoryBot.create(:shift, shift_date: @last_training_date + 5.days, shift_type_id: @g1end.id)
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal true
      #
      #     shift.disabled = true
      #     shift.save!
      #     shift.can_select(@rookie_user, HostUtility.can_select_params_for(@rookie_user)).must_equal false
      #   end
      #
      #   it 'round 4 - rookies:  - cannot pick if already working that day' do
      #     setup_vars_for_rookies
      #     run_cannot_pick_working_days(@round4_date, @rookie_user)
      #   end
      # end
    end
  end

  describe 'assign team leaders' do
    it 'should set all monday shifts for team leader 1' do
      u = User.with_role(:team_leader).first
      params = {'monday' => u.name}
      Shift.assign_team_leaders(params)
      shift_list = Shift.team_leader_shifts

      shift_list.each do |shift|
        next if shift.shift_date.cwday != 1

        shift.user_id.must_equal u.id
      end
    end
  end

  describe 'is_tour?' do
    it 'should recognize tour shifts' do
      setup_vars
      shift = FactoryBot.create(:shift, shift_date: Date.parse(Date.today.strftime('%Y-%m-%d')), shift_type_id: @p1end.id)
      TOUR_TYPES.each do |shift_type|
        shift.shift_type = FactoryBot.create(:shift_type, short_name: shift_type)
        shift.save
        shift.is_tour?.must_equal true
      end
    end

    it 'should recognize non-tour shifts' do
      setup_vars
      shift = FactoryBot.create(:shift, shift_date: Date.parse(Date.today.strftime('%Y-%m-%d')), shift_type_id: @p1end.id)
      NON_TOUR_TYPES.each do |shift_type|
        shift.shift_type = FactoryBot.create(:shift_type, short_name: shift_type)
        shift.save
        _(shift.is_tour?).must_equal false
      end
    end
  end
  end

