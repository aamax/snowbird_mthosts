require "test_helper"

class ShiftTest < ActiveSupport::TestCase
  before do
    @sys_config = SysConfig.first
    @p1 = ShiftType.find_by_short_name('P1')
    @p2 = ShiftType.find_by_short_name('P2')
    @p3 = ShiftType.find_by_short_name('P3')
    @p4 = ShiftType.find_by_short_name('P4')
    @g1 = ShiftType.find_by_short_name('G1weekend')
    @g1f = ShiftType.find_by_short_name('G1friday')
    @g2 = ShiftType.find_by_short_name('G2weekend')
    @g3 = ShiftType.find_by_short_name('G3weekend')
    @g4 = ShiftType.find_by_short_name('G4weekend')
    @g5 = ShiftType.find_by_short_name('G5')
    @c3 = ShiftType.find_by_short_name('C3')
    @c4 = ShiftType.find_by_short_name('C4')
    @bg = ShiftType.find_by_short_name('BG')
    @sh = ShiftType.find_by_short_name('SH')

    @g1_friday = FactoryGirl.create(:shift_type, :short_name => 'G1friday')
    @g1_weekend = FactoryGirl.create(:shift_type, :short_name => 'G1weekend')
    @p1_weekend = FactoryGirl.create(:shift_type, :short_name => 'P1weekend')
  end

  describe 'trainee_can_pick?' do
    before do
      # make g1 weekend and g1 friday shift types
      # make shifts using g1 weekend and g1 friday shifts
      @sh1 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.days,
                                  :shift_type_id => @sh.id, :user_id => nil)
      @sh2 = FactoryGirl.create(:shift, :shift_date => Date.today + 4.days,
                                :shift_type_id => @sh.id, :user_id => nil)
      @sh3 = FactoryGirl.create(:shift, :shift_date => Date.today + 3.days,
                                :shift_type_id => @sh.id, :user_id => nil)
      @sh4 = FactoryGirl.create(:shift, :shift_date => Date.today + 4.days,
                                :shift_type_id => @sh.id, :user_id => nil)
      @weekend_shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week,
                                          :shift_type_id => @g1_weekend.id, :user_id => nil)
      @friday_shift = FactoryGirl.create(:shift, :shift_date => Date.today + 1.week + 1.day,
                                        :shift_type_id => @g1_friday.id, :user_id => nil)
    end

    # no trainees on this date
    it 'true if no trainees on this date' do
      @weekend_shift.users_on_date.count.must_equal 0
      @weekend_shift.trainee_can_pick?.must_equal true
      @friday_shift.users_on_date.count.must_equal 0
      @friday_shift.trainee_can_pick?.must_equal true
    end

    # date is not weekend or friday
    it 'date is not weekend or friday' do
      shift = Shift.find_by_shift_type_id(@c3.id)
      shift.trainee_can_pick?.must_equal false
    end

    describe "trainees can pick?" do
      before do
        @rookie2 = FactoryGirl.create(:user, :email => 'f1.user@example.com', :start_year => @sys_config.season_year, :active_user => true)
        @rookie2.shifts << @sh1
        @rookie2.shifts << @sh2
        @rookie2.shifts << @weekend_shift
        @rookie2.shifts << @friday_shift
        @weekend_shift2 = FactoryGirl.create(:shift, :shift_date => @weekend_shift.shift_date,
                                            :shift_type_id => @g1_weekend.id, :user_id => nil)
        @friday_shift2 = FactoryGirl.create(:shift, :shift_date => @friday_shift.shift_date,
                                           :shift_type_id => @g1_friday.id, :user_id => nil)
      end

      # 1 trainee on friday
      it "one on friday returns false" do
        @friday_shift2.trainee_can_pick?.must_equal false
      end

      # 1 trainee on weekend
      it 'one on weekend returns true' do
        @weekend_shift2.trainee_can_pick?.must_equal true
      end

      # 2 trainees on weekend
      it 'two on weekend returns false' do
        @rookie3 = FactoryGirl.create(:user, :email => 'f3.user@example.com', :start_year => @sys_config.season_year, :active_user => true)
        @rookie3.shifts << @sh3
        @rookie3.shifts << @sh4
        @rookie3.shifts << @weekend_shift2
        @weekend_shift3 = FactoryGirl.create(:shift, :shift_date => @weekend_shift.shift_date,
                                             :shift_type_id => @g1_weekend.id, :user_id => nil)
        @weekend_shift3.trainee_can_pick?.must_equal false
      end
    end
  end

  describe "can select - all trainees" do
    before do
      # set up 5 hosts with shadow days
      @day1 = Date.today + 3.weeks + 3.days
      @day2 = Date.today + 3.weeks + 4.days
      @day3 = Date.today + 3.weeks + 5.days
      @day4 = Date.today + 3.weeks + 6.days

      @rookies = []
      (0..1).each do |n|
        r = FactoryGirl.create(:user, :email => "user_mail#{n}@example.com", :start_year => @sys_config.season_year, :active_user => true)
        @rookies << r

        sh1 = FactoryGirl.create(:shift, :shift_date => @day1,
                                  :shift_type_id => @sh.id, :user_id => nil)
        sh2 = FactoryGirl.create(:shift, :shift_date => @day2,
                                  :shift_type_id => @sh.id, :user_id => nil)
        r.shifts << sh1
        r.shifts << sh2

        r = FactoryGirl.create(:user, :email => "user_mail2#{n}@example.com", :start_year => @sys_config.season_year, :active_user => true)
        @rookies << r

        sh1 = FactoryGirl.create(:shift, :shift_date => @day3,
                                 :shift_type_id => @sh.id, :user_id => nil)
        sh2 = FactoryGirl.create(:shift, :shift_date => @day4,
                                 :shift_type_id => @sh.id, :user_id => nil)
        r.shifts << sh1
        r.shifts << sh2
      end
    end

    it "can select a g1 for a rookie not working on a day with 2 shadow rookies" do
      @friday_shift = FactoryGirl.create(:shift, :shift_date => @day3,
                                         :shift_type_id => @g1_friday.id, :user_id => nil)
      @weekend_shift = FactoryGirl.create(:shift, :shift_date => @day4,
                                           :shift_type_id => @g1_weekend.id, :user_id => nil)
      @friday_shift.can_select(@rookies[0]).must_equal true
      @weekend_shift.can_select(@rookies[0]).must_equal true
    end

    it "can select g1 on weekend with one other trainee and 2 shadows" do
      @weekend_shift = FactoryGirl.create(:shift, :shift_date => @day4,
                                          :shift_type_id => @g1_weekend.id, :user_id => nil)

      @weekend_shift2 = FactoryGirl.create(:shift, :shift_date => @day4,
                                          :shift_type_id => @g1_weekend.id, :user_id => nil)

      @rookies[0].shifts << @weekend_shift
      @weekend_shift2.can_select(@rookies[2]).must_equal true
    end

    it "can not select g1 for a rookie working on friday with 2 shadows and another trainee" do
      @friday_shift = FactoryGirl.create(:shift, :shift_date => @day4,
                                          :shift_type_id => @g1_friday.id, :user_id => nil)

      @friday_shift2 = FactoryGirl.create(:shift, :shift_date => @day4,
                                           :shift_type_id => @g1_friday.id, :user_id => nil)

      @rookies[0].shifts << @friday_shift
      @friday_shift2.can_select(@rookies[2]).must_equal false
    end

    it "can not select g1 on weekend with two other trainee and 2 shadows" do
      @weekend_shift = FactoryGirl.create(:shift, :shift_date => @day4,
                                          :shift_type_id => @g1_weekend.id, :user_id => nil)

      @weekend_shift2 = FactoryGirl.create(:shift, :shift_date => @day4,
                                           :shift_type_id => @g1_weekend.id, :user_id => nil)

      @rookies[0].shifts << @weekend_shift
      @rookies[2].shifts << @weekend_shift2

      @weekend_shift3 = FactoryGirl.create(:shift, :shift_date => @day4,
                                           :shift_type_id => @g1_weekend.id, :user_id => nil)
      r = FactoryGirl.create(:user, :email => "user_mail_new@example.com", :start_year => @sys_config.season_year, :active_user => true)

      @weekend_shift3.can_select(r).must_equal false
    end
  end
  
  describe 'can select edge cases' do
    # TODO finish tests
    
    
    before do
      @day = Date.today + 5.weeks
      
      # give user shadow shifts
      @user = FactoryGirl.create(:user, :email => "user_mail_new@example.com", :start_year => @sys_config.season_year, :active_user => true)
      sh1 = FactoryGirl.create(:shift, :shift_date => @day,
                                 :shift_type_id => @sh.id, :user_id => nil)
      sh2 = FactoryGirl.create(:shift, :shift_date => @day + 1.day,
                                 :shift_type_id => @sh.id, :user_id => nil)
      @user.shifts << sh1
      @user.shifts << sh2      
    end
    
    describe 'after training is over' do
      before do
        @sys_config.bingo_start_date = Date.today - 4.days
        @sys_config.save!

        # create and select shifts to finish training
        (2..5).each do |n|
          shift = FactoryGirl.create(:shift, :shift_date => @day + n.days,
                                             :shift_type_id => @g1_weekend.id, :user_id => nil)
          @user.shifts << shift
        end
        shift = FactoryGirl.create(:shift, :shift_date => @day + 8.days,
                                   :shift_type_id => @g1_weekend.id, :user_id => nil)
        @user.shifts << shift
      end

      it 'cannot pick non rookie shifts before last selected rookie shift' do
        dt = @user.shifts[-1].shift_date
        shift = FactoryGirl.create(:shift, :shift_date => dt - 1.day,
                                   :shift_type_id => @p1_weekend.id, :user_id => nil)
        shift.can_select(@user).must_equal false
      end

      it 'cannot pick g1 weekend shift inside 5th rookie shift, if all shifts picked for round' do
        dt = @user.shifts[-1].shift_date
        shift = FactoryGirl.create(:shift, :shift_date => dt - 1.day,
                                   :shift_type_id => @g1_weekend.id, :user_id => nil)
        shift.can_select(@user).must_equal false
      end
    end
  end

  describe "can_select with some rookies past trainee" do
    before do
      @rookies = []
      (0..5).each do |u|
        r = FactoryGirl.create(:user, :email => "user_mail#{u}@example.com", :start_year => @sys_config.season_year, :active_user => true)
        @rookies << r
      end
      @og1 = @rookies[0]
      @og2 = @rookies[1]
      @tr1 = @rookies[2]
      @tr2 = @rookies[3]

      @start_date = Date.today + 2.days
      (0..1).each do |d|
        (0..1).each do |s|
          # make a shadow day
          sh1 = FactoryGirl.create(:shift, :shift_date => @start_date + s.days,
                                   :shift_type_id => @sh.id, :user_id => nil)
          @rookies[d].shifts << sh1
        end

        (0..4).each do |g1|
          # make a g1 day
          s = FactoryGirl.create(:shift, :shift_date => @start_date + g1.days + 3.days,
                             :shift_type_id => @g1_weekend.id, :user_id => nil)
          @rookies[d].shifts << s
        end
      end

      # give other users shadow shifts too
      (2..3).each do |u|
        r = @rookies[u]
        sh1 = FactoryGirl.create(:shift, :shift_date => @start_date,
                                 :shift_type_id => @sh.id, :user_id => nil)
        sh2 = FactoryGirl.create(:shift, :shift_date => @start_date + 1.day,
                                 :shift_type_id => @sh.id, :user_id => nil)
        r.shifts << sh1
        r.shifts << sh2
      end

      (4..5).each do |d|
        sh1 = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                 :shift_type_id => @sh.id, :user_id => nil)
        sh2 = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks + 1.day,
                                 :shift_type_id => @sh.id, :user_id => nil)
        @rookies[d].shifts << sh1
        @rookies[d].shifts << sh2
      end
      @g1f_1 = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                  :shift_type_id => @g1_friday.id, :user_id => nil)
      @g1f_2 = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                  :shift_type_id => @g1_friday.id, :user_id => nil)
      @g1w_1 = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks + 1.day,
                                  :shift_type_id => @g1_weekend.id, :user_id => nil)
      @g1w_2 = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks + 1.day,                                  :shift_type_id => @g1_weekend.id, :user_id => nil)
    end

    it "2 rookie shadows, 1 rookie past training, can select g1 for 4th rookie on friday" do
      @g1f_2.can_select(@tr1).must_equal true
    end

    it "2 rookie shadows, 1 rookie past training, can select g1 for 4th rookie on weekend" do
      @g1w_2.can_select(@tr1).must_equal true
    end

    it "2 rookie shadows, 1 rookie past training, 1 trainee, can select g1 for 5th rookie on weekend" do
      @tr2.shifts << @g1w_2
      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks + 1.day,
                              :shift_type_id => @g1_weekend.id, :user_id => nil)
      shift.can_select(@tr1).must_equal true
    end

    it "cannot select - 2 shadows, 1 past training, 1 trainee on friday" do
      @tr2.shifts << @g1f_2
      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                 :shift_type_id => @g1_friday.id, :user_id => nil)
      shift.can_select(@tr1).must_equal false
    end

    it "cannot select - 2 shadows, 1 past training, 2 trainee on weekend" do
      @tr2.shifts << @g1w_2
      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks + 1.day,
                                 :shift_type_id => @g1_weekend.id, :user_id => nil)
      @tr1.shifts << shift
      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks + 1.day,
                                 :shift_type_id => @g1_weekend.id, :user_id => nil)
      shift.can_select(@rookies[5]).must_equal false
    end

    it "can select if past training and one trainee on friday" do
      @sys_config.bingo_start_date = Date.today - 3.weeks
      @sys_config.save!

      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                 :shift_type_id => @g1_friday.id, :user_id => nil)
      @tr2.shifts << shift
      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                 :shift_type_id => @g1_friday.id, :user_id => nil)
      shift.can_select(@og1).must_equal true
    end

    it "can select if past training and two trainees on weekend" do
      @sys_config.bingo_start_date = Date.today - 3.weeks
      @sys_config.save!

      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                 :shift_type_id => @g1_weekend.id, :user_id => nil)
      @tr2.shifts << shift
      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                 :shift_type_id => @g1_weekend.id, :user_id => nil)
      @tr2.shifts << shift
      shift = FactoryGirl.create(:shift, :shift_date => @start_date + 3.weeks,
                                 :shift_type_id => @g1_weekend.id, :user_id => nil)
      shift.can_select(@og1).must_equal true
    end
  end

  describe "round one shift type" do
    describe 'should return true' do
      it 'shift is G1' do
        @g1s = FactoryGirl.create(:shift, :shift_type_id => @g1.id, :shift_date => Date.today)
        @g1s.round_one_rookie_shift?.must_equal true
      end

      it 'shift is G2' do
        @g2s = FactoryGirl.create(:shift, :shift_type_id => @g2.id, :shift_date => Date.today)
        @g2s.round_one_rookie_shift?.must_equal true
      end

      it 'shift is G3' do
        @g3s = FactoryGirl.create(:shift, :shift_type_id => @g3.id, :shift_date => Date.today)
        @g3s.round_one_rookie_shift?.must_equal true
      end

      it 'shift is G4' do
        @g4s = FactoryGirl.create(:shift, :shift_type_id => @g4.id, :shift_date => Date.today)
        @g4s.round_one_rookie_shift?.must_equal true
      end
    end

    describe 'should return false' do
      it 'shift is C3' do
        @c3s = FactoryGirl.create(:shift, :shift_type_id => @c3.id, :shift_date => Date.today)
        @c3s.round_one_rookie_shift?.must_equal false
      end

      it 'shift is C4' do
        @c4s = FactoryGirl.create(:shift, :shift_type_id => @c4.id, :shift_date => Date.today)
        @c4s.round_one_rookie_shift?.must_equal false
      end

      it 'shift is G3 Friday' do
        @g3f = FactoryGirl.create(:shift_type, short_name: 'G3friday')
        @g3fs = FactoryGirl.create(:shift, :shift_type_id => @g3f.id, :shift_date => Date.today)
        @g3fs.round_one_rookie_shift?.must_equal false
      end

      it 'shift is G4 Friday' do
        @g4f = FactoryGirl.create(:shift_type, short_name: 'G4friday')
        @g4fs = FactoryGirl.create(:shift, :shift_type_id => @g4f.id, :shift_date => Date.today)
        @g4fs.round_one_rookie_shift?.must_equal false
      end

      it 'shift is P1' do
        @p1s = FactoryGirl.create(:shift, :shift_type_id => @p1.id, :shift_date => Date.today)
        @p1s.round_one_rookie_shift?.must_equal false
      end

      it 'shift is P2' do
        @p2s = FactoryGirl.create(:shift, :shift_type_id => @p2.id, :shift_date => Date.today)
        @p2s.round_one_rookie_shift?.must_equal false
      end

      it 'shift is P3' do
        @p3s = FactoryGirl.create(:shift, :shift_type_id => @p3.id, :shift_date => Date.today)
        @p3s.round_one_rookie_shift?.must_equal false
      end

      it 'shift is P4' do
        @p4s = FactoryGirl.create(:shift, :shift_type_id => @p4.id, :shift_date => Date.today)
        @p4s.round_one_rookie_shift?.must_equal false
      end
    end
  end

  describe 'assign team leaders' do
    before do
      @tl = ShiftType.find_by_short_name('TL')
      @tl_shifts = Shift.where("shift_type_id = #{@tl.id}")
    end

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
end
