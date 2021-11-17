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

  def disabled
    false
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
    ShiftType.find_by(short_name: short_name)
  end

  def shift_status_id
    0
  end

  def meeting?
    false
  end

  def non_mountain_meeting?
    false
  end

  def can_drop(user)
    return true if user.admin?

    return false if self.shift_date < Date.today()
    return false if user.id != user_id
    return false if self.shift_date <= Date.today + 13.days
    true
  end
end
