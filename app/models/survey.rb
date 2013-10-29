# == Schema Information
#
# Table name: surveys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  date        :datetime
#  count       :integer
#  survey_type :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Survey < ActiveRecord::Base
  attr_accessible :date, :count, :survey_type

  belongs_to :user
end
