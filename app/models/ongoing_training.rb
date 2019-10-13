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
end
