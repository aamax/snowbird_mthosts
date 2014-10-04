require "test_helper"

class UserTest < ActiveSupport::TestCase
  before do
    @sys_config = SysConfig.first
    @rookie_user = User.find_by_name('rookie')
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @team_leader = User.find_by_name('teamlead')
    @user = User.create(name: 'test user', email: 'user@example.com')

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
    @g1f = ShiftType.find_by_short_name('G1friday')
    @g2f = ShiftType.find_by_short_name('G2friday')
    @g3f = ShiftType.find_by_short_name('G3friday')
    @g4f = ShiftType.find_by_short_name('G4friday')
    @g5 = ShiftType.find_by_short_name('G5')
    @c1 = ShiftType.find_by_short_name('C1')
    @c2 = ShiftType.find_by_short_name('C2')
    @c3 = ShiftType.find_by_short_name('C3')
    @c4 = ShiftType.find_by_short_name('C4')
    @bg = ShiftType.find_by_short_name('BG')

    @start_date = (Date.today()  + 20.days)
  end

  describe 'tour ratio' do
    before do
      @p2.tasks = "peruvian morning tour"
      @p2.save
    end

    it 'should not count meetings in calc' do
      mtg = FactoryGirl.create(:shift_type, 'short_name' => 'M1')
      shift = FactoryGirl.create(:shift, :shift_type_id => mtg.id, :shift_date => Date.today)
      @user.shifts << shift
      @user.tour_ratio.must_equal 0
    end

    it 'should have a 0 ratio if user has no shifts' do
      @user.shifts.size.must_equal 0
      @user.tour_ratio.must_equal 0
    end

    it 'should have a ratio of 100 if all shifts are tours' do
      (1..10).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 100
    end

    it 'should have a ratio of 50 if half of the shifts are tours' do
      (1..10).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
        ashift = FactoryGirl.create(:shift, :shift_type_id => @c4.id, :shift_date => Date.today - 1.month - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 50
    end

    it 'should have a ratio of 25 if a quarter of the shifts are tours' do
      (1..5).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
      end
      (1..15).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @c4.id, :shift_date => Date.today - 1.month - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 25
    end

    it 'should have a ratio of 75 is 3 quarters of the shifts are tours' do
      (1..15).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today - s.days)
        @user.shifts << ashift
      end
      (1..5).each do |s|
        ashift = FactoryGirl.create(:shift, :shift_type_id => @c4.id, :shift_date => Date.today - 1.month - s.days)
        @user.shifts << ashift
      end

      @user.tour_ratio.must_equal 75
    end
  end

  describe "is_trainee_on_date" do
    before do
      r1s = [@g1.id, @g2.id, @g3.id, @g4.id]
      @shadows = Shift.where(:shift_type_id => @sh.id)
      @round_ones = Shift.where("shift_type_id in (#{r1s.join(',')})")
    end

    it 'rookie no selections: false - needs shadows' do
      @rookie_user.is_trainee_on_date(Shift.first.shift_date).must_equal false
    end

    it "rookie with 1 shadow: false - needs shadow" do
      @rookie_user.shifts << @shadows[0]
      @rookie_user.is_trainee_on_date(@shadows[0].shift_date + 3.days).must_equal false
    end

    it "rookie with 2 shadows: true" do
      @rookie_user.shifts << @shadows[0]
      @rookie_user.shifts << @shadows[1]
      @rookie_user.is_trainee_on_date(@shadows[1].shift_date + 3.days).must_equal true
    end

    it "rookie with 2 shadows and 1 - 5 round one shifts: true" do
      @rookie_user.shifts << @shadows[0]
      @rookie_user.shifts << @shadows[1]
      (0..3).each do |n|
        @rookie_user.shifts << @round_ones[n]

        @rookie_user.is_trainee_on_date(@round_ones[n].shift_date + 3.days).must_equal true
      end

      @rookie_user.shifts << @round_ones[4]
      @rookie_user.is_trainee_on_date(@shadows[1].shift_date + 3.days).must_equal false
    end
  end

  describe "shadow date" do
    before  do
      @sys_config.bingo_start_date = (Date.today -  9.days)
      @sys_config.save!
      Shift.all.each do |s|
        if (s.can_select(@rookie_user) == true)
          @rookie_user.shifts << s
          @last_date = s.shift_date if s.shadow?
        end
      end
    end
    it "should return correct shadow date" do
      @last_date.must_equal @rookie_user.last_shadow
    end
  end

  describe "last round1 date" do
    before  do
      @sys_config.bingo_start_date = (Date.today -  9.days)
      @sys_config.save!
      iCnt = 0
      Shift.all.each do |s|
        if ((s.can_select(@rookie_user) == true))
          @rookie_user.shifts << s
          if ((iCnt < 5) && (s.round_one_rookie_shift?))
            @last_rookie_shift = s
            iCnt += 1
          end
        end
      end
    end

    it "should return correct shadow date" do
      @last_rookie_shift.shift_date.must_equal @rookie_user.round_one_end_date
    end
  end

  describe "seniority" do
    it "should be Supervisor for John Cotter" do
      @user.name = 'John Cotter'
      @user.seniority.must_equal 'Supervisor'
    end

    it 'should be Rookie for rookie user' do
      @rookie_user.seniority.must_equal 'Rookie'
    end

    it 'should be Group 3 (Newer) for first year user' do
      @group3_user.seniority.must_equal 'Group 3 (Newer)'
    end

    it 'should be Group 2 (Middle) for middle group users' do
      @group2_user.seniority.must_equal 'Group 2 (Middle)'
    end

    it 'should be Group 1 (Senior) for senior user' do
      @group1_user.seniority.must_equal 'Group 1 (Senior)'
    end

    it 'should be Rookie for rookie user' do
      @rookie_user.seniority.must_equal 'Rookie'
    end
  end

  describe 'seniority Group' do
    it "should return correct group values for each user" do
      @user.active_user = false
      @user.seniority_group.must_equal 5

      @group1_user.seniority_group.must_equal 1
      @group2_user.seniority_group.must_equal 2
      @group3_user.seniority_group.must_equal 3
      @rookie_user.seniority_group.must_equal 4
    end
  end


end