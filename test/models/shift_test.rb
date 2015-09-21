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
    @c1 = ShiftType.find_by_short_name('C1weekend')
    @c2 = ShiftType.find_by_short_name('C2weekend')
    @c3 = ShiftType.find_by_short_name('C3weekend')
    @c4 = ShiftType.find_by_short_name('C4weekend')
    @bg = ShiftType.find_by_short_name('BG')
    @sh = ShiftType.find_by_short_name('SH')

    @g1_friday = FactoryGirl.create(:shift_type, :short_name => 'G1friday')
    @g1_weekend = FactoryGirl.create(:shift_type, :short_name => 'G1weekend')
    @p1_weekend = FactoryGirl.create(:shift_type, :short_name => 'P1weekend')
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
