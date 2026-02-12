FactoryBot.define do
  factory :goal do
    association :user
    
    sequence(:title) { |n| "目標#{n}" }
    description { '目標の説明' }
    target_date { 1.year.from_now }
    status { 'active' }
  end
end