# == Schema Information
#
# Table name: training_dates
#
#  id         :integer          not null, primary key
#  shift_date :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "test_helper"

class TrainingDateTest < ActiveSupport::TestCase
  def training_date
    @training_date ||= TrainingDate.new(shift_date: Date.today)
  end

  def test_valid
    assert training_date.valid?
  end

  def test_relationships_are_correct
    trainer_user = User.create(email: 'test1@test.com', password: 'password')
    trainee_user = User.create(email: 'test2@test.com', password: 'password')

    obj = training_date
    obj.save

    obj.ongoing_trainings << OngoingTraining.create(user: trainee_user, is_trainer: false)
    obj.ongoing_trainings << OngoingTraining.create(user: trainer_user, is_trainer: true)

    assert_equal 1, obj.trainers.count
    assert_equal 1, obj.trainees.count

    assert_equal trainer_user, obj.trainers.first
    assert_equal trainee_user, obj.trainees.first
  end

  # TODO can only select trainings if you are not working, don't already have a training and not a rookie
  # TODO OR, if you are a trainer and aren't already training that day - and it's a trainer shift
end
