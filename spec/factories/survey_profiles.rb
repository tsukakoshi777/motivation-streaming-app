# frozen_string_literal: true

FactoryBot.define do
  factory :survey_profile do
    association :user
    association :streaming_platform
    association :streaming_category
    association :streaming_experience

    weekly_frequency { 3 }
    average_listeners { 100 }
    total_listeners { 1000 }
    listener_dropout_rate { 2 }
    motivation_level { 3 }

    # survey_response と survey_result を自動作成
    after(:create) do |survey_profile|
      create(:survey_response, survey_profile: survey_profile)
      create(:survey_result, survey_profile: survey_profile)
    end
  end
end
