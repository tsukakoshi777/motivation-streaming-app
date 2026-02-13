FactoryBot.define do
  factory :streaming_experience do
    sequence(:name) { |n| "経験レベル#{n}" }
  end
end