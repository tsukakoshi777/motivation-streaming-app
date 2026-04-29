# frozen_string_literal: true

FactoryBot.define do
  factory :authentication do
    association :user
    provider { 'google' }
    uid { '123456789' }
  end
end
