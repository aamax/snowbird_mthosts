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

  describe "shadow date" do
    before  do
      @sys_config.bingo_start_date = (Date.today -  9.days)
      @sys_config.save!
      Shift.all.each do |s|
        if ((s.can_select(@rookie_user) == true))
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