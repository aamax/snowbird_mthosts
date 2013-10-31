# == Schema Information
#
# Table name: surveys
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  date       :datetime
#  count      :integer
#  type1      :integer
#  type2      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :survey do
  end
end
