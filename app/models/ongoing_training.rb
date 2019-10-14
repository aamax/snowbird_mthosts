# == Schema Information
#
# Table name: trainings
#
#  id               :integer          not null, primary key
#  user_id          :integer
#  training_date_id :integer
#  is_trainer       :boolean
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class OngoingTraining < ActiveRecord::Base
  belongs_to :training_date
  belongs_to :user

  def is_trainer?
    is_trainer
  end

  def shift_date
    training_date.shift_date
  end

  def day_of_week
    shift_date.strftime("%a")
  end

  def short_name
    'OT'
  end

  def shift_type
    # if ShiftType.find_by(short_name: 'OT').nil?
    #   ShiftType.create(short_name: 'OT', description: 'Ongoing Mt Host Training',
    #                    start_time: '08:00', end_time: '12:00', tasks: 'Training as Needed')
    # end
    ShiftType.find_by(short_name: short_name)
  end

  def can_drop(unused)
    false
  end
end