# frozen_string_literal: true

FactoryBot.define do
  factory :streaming_platform do
    sequence(:name) { |n| "プラットフォーム#{n}" }
  end
end
