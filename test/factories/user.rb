FactoryGirl.define do
  sequence :email do |n|
    "email#{n}@example.com"
  end
  sequence :name do |n|
    "name-#{n}"
  end

  factory :user do
    name
    email
    password "password"
  end

end