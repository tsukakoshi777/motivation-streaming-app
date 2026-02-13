FactoryBot.define do
  factory :streaming_category do
    sequence(:name) { |n| "カテゴリ#{n}" }
  end
end