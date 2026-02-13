FactoryBot.define do
  factory :streaming_platform do
    sequence(:name) { |n| "プラットフォーム#{n}" }
  end
end