# frozen_string_literal: true

FactoryBot.define do
  factory :streaming_category do
    sequence(:name) { |n| "カテゴリ#{n}" }
  end
end
