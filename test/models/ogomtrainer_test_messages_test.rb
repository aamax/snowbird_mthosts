require "test_helper"

class OGOMTrainerMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @trainer = User.find_by_name('g1')
    @trainer.add_role :ongoing_trainer
    @user = User.find_by_name('g3')

    @training_date = TrainingDate.create(shift_date: "#{Date.today.year}-01-01")
    @trainer_shift = OngoingTraining.create(user: nil, is_trainer: true, training_date: @training_date)
    @trainee_shift = OngoingTraining.create(user: nil, is_trainer: false, training_date: @training_date)
  end

  def test_trainer_shift_count_has_training_shifts
    assert_equal 2, @trainer.shifts_for_credit.count
    @trainer.ongoing_trainings << @trainer_shift
    assert_equal 3, @trainer.shifts_for_credit.count
  end

  def test_trainee_shift_count_does_not_have_training_shifts
    assert_equal 2, @user.shifts_for_credit.count
    @user.ongoing_trainings << @trainee_shift
    assert_equal 2, @user.shifts_for_credit.count
  end
end
