# == Schema Information
#
# Table name: riders
#
#  id             :integer          not null, primary key
#  host_hauler_id :integer
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryGirl.define do
  factory :rider do
    host_hauler_id 1
    user_id 1
  end
end
