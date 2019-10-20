FactoryBot.define do
  factory :ongoing_training do
    training_date_id { 1 }
    user_id { 1 }
    is_trainer { false }
  end
end