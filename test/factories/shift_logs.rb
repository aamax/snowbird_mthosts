# == Schema Information
#
# Table name: shift_logs
#
#  id           :integer          not null, primary key
#  change_date  :datetime
#  user_id      :integer
#  shift_id     :integer
#  action_taken :string
#  note         :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :shift_log do
    change_date { "" }
    user_id { "" }
    shift_id { "" }
    action_taken  { "" }
    note { "MyText" }
  end
end
