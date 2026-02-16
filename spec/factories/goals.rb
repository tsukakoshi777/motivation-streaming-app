# frozen_string_literal: true

FactoryBot.define do
  factory :goal do
    association :user
    association :survey_profile
  end
end
