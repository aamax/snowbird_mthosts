require "test_helper"

class TrainerMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @trainer = User.find_by_name('g1')
    @trainer.add_role :trainer
    @trtype = ShiftType.find_by(short_name: 'TR')

    (1..50).each do |n|
      FactoryGirl.create(:shift, shift_type_id: @trtype.id, shift_date: Date.today + n.days)
    end
  end

  describe "trainer messages" do
    def test_show_trainer_shift_count_pre_bingo
      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@trainer, 0)
      @sys_config.save

      Shift.all.each do |s|
        if s.trainer? && s.can_select(@trainer)
          @trainer.shifts << s
        end
      end
      (@trainer.shifts.count == 20).must_equal true
      (@trainer.trainer_shift_count == 18).must_equal true
      msgs = @trainer.shift_status_message
      msgs.include?("No Selections Until #{@sys_config.bingo_start_date}.").must_equal true
      msgs.include?("18 trainer shifts selected").must_equal true
    end

    def test_show_surveyor_shift_count_in_round_4
      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@trainer, 4)
      @sys_config.save

      Shift.all.each do |s|
        if s.trainer? && s.can_select(@trainer)
          @trainer.shifts << s
        end
      end
      (@trainer.shifts.count == 20).must_equal true
      (@trainer.trainer_shift_count == 18).must_equal true
      msgs = @trainer.shift_status_message
      msgs.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
      msgs.include?("18 trainer shifts selected").must_equal true
    end

    def test_show_surveyor_shift_count_post_bingo
      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@trainer, 6)
      @sys_config.save

      Shift.all.each do |s|
        if s.trainer? && s.can_select(@trainer)
          @trainer.shifts << s
        end
      end
      (@trainer.shifts.count == 52).must_equal true
      (@trainer.trainer_shift_count == 50).must_equal true
      msgs = @trainer.shift_status_message
      msgs.include?("You have at least 20 shifts selected").must_equal true
      msgs.include?("50 trainer shifts selected").must_equal true
    end
  end
end


