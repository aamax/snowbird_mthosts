# == Schema Information
#
# Table name: training_dates
#
#  id         :integer          not null, primary key
#  shift_date :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TrainingDate < ActiveRecord::Base
  has_many :ongoing_trainings
  # has_many :users, through: :trainings
  # has_many :trainee_users, class_name: 'User', through: :trainers

  # has_many :trainer_users, class_name: 'User', through: :trainees
  # has_many :trainer_users

  validates   :shift_date,  :presence => true

  # def add_trainer user
  #   trainer_users << Trainer.create(user: user)
  # end
  #
  # def add_trainee user
  #   trainee_users << Trainee.create(user: user)
  # end

  def trainees
    users = []
    ongoing_trainings.each do |t|
      users << t.user unless t.is_trainer?
    end
    users
  end

  def trainers
    users = []
    ongoing_trainings.each do |t|
      users << t.user if t.is_trainer?
    end
    users
  end

  def trainee_shifts_open
    ongoing_trainings.where("is_trainer = false and user_id is null").count
  end

  def trainer_shifts_open
    ongoing_trainings.where("is_trainer = true and user_id is null").count
  end
end
