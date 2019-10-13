# == Schema Information
#
# Table name: shifts
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  shift_type_id   :integer          not null
#  shift_status_id :integer          default(1), not null
#  shift_date      :date
#  day_of_week     :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  short_name      :string
#  disabled        :boolean
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :shift do
    shift_status_id { 1 }
  end
end
