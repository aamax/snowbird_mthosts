require "test_helper"

class ShiftTest < ActiveSupport::TestCase


  describe "round one shift type" do
    before do
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
    end

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

  # TODO
  describe 'rookie count' do
    describe 'rookies working training shifts' do
      describe 'friday' do
        it 'no rookies'
        it '1 rookie'
        it '1 training rookie, 1 past training'
        it '1 senior, 1 middle, 1 newer, 1 rookie'
      end

      describe 'weekend' do
        it 'no rookies'
        it '1 rookie'
        it '1 training rookie, 1 past training'
        it '1 senior, 1 middle, 1 newer, 1 rookie'
      end
    end
  end


end
