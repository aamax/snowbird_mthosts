# == Schema Information
#
# Table name: galleries
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  category         :string(255)      default("general")
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pic_file_name    :string(255)
#  pic_content_type :string(255)
#  pic_file_size    :integer
#  pic_updated_at   :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :gallery do
  end
end
