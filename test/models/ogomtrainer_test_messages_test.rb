# require "test_helper"
#
# class OGOMTrainerMessageTest < ActiveSupport::TestCase
#   def setup
#     HostConfig.initialize_values
#
#     @sys_config = SysConfig.first
#     @trainer = User.find_by_name('g1')
#     @trainer.add_role :ongoing_trainer
#     @user = User.find_by_name('g3')
#
#     @training_date = TrainingDate.create(shift_date: "#{Date.today.year}-01-01")
#     @trainer_shift = OngoingTraining.create(user: nil, is_trainer: true, training_date: @training_date)
#     @trainee_shift = OngoingTraining.create(user: nil, is_trainer: false, training_date: @training_date)
#   end
#
#   def test_trainer_shift_count_has_training_shifts
#     assert_equal 2, @trainer.shifts_for_credit.count
#
#     msgs = @trainer.shift_status_message
#     msgs.include?('You Do Not Have Any Training Shifts Yet.').must_equal true
#
#     @trainer.ongoing_trainings << @trainer_shift
#     assert_equal 3, @trainer.shifts_for_credit.count
#
#     msgs = @trainer.shift_status_message
#     msgs.include?('You Are Scheduled As An On Going On Mountain Training Trainer.').must_equal true
#   end
#
#   def test_trainee_shift_count_does_not_have_training_shifts
#     assert_equal 2, @user.shifts_for_credit.count
#
#     msgs = @user.shift_status_message
#     msgs.include?('You have not signed up for Ongoing On Mountain Training Yet.').must_equal true
#
#     @user.ongoing_trainings << @trainee_shift
#     assert_equal 2, @user.shifts_for_credit.count
#
#     msgs = @user.shift_status_message
#     msgs.include?('You have selected an Ongoing On Mountain Training Shift.').must_equal true
#   end
#
#   def test_rookies_do_not_pick_ogomt
#     user = User.find_by(email: 'email1@example.com')
#     user.rookie?.must_equal true
#
#     msgs = user.shift_status_message
#     msgs.include?('You do not need to select an Ongoing On Mountain Training Shift.').must_equal true
#   end
# end
