# == Schema Information
#
# Table name: shift_types
#
#  id          :integer          not null, primary key
#  short_name  :string(255)      not null
#  description :string(255)      not null
#  start_time  :string(255)
#  end_time    :string(255)
#  tasks       :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :shift_type do
    short_name   { 'P1' }
    description  { 'Peruvian' }
    start_time   { '08:00' }
    end_time     { '16:00' }
  end
end
