FactoryBot.define do
  factory :goal do
    association :user
    association :survey_profile
  end
end