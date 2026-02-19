# frozen_string_literal: true

FactoryBot.define do
  factory :survey_response do
    association :survey_profile
    happy_moment { 'テスト嬉しかったこと' }
    sad_moment { 'テスト悲しかったこと' }
    streaming_reasons { '収益化したい,趣味として楽しみたい' }
    streaming_reasons_other { '' }
    desired_streaming_style { 'テスト理想の配信スタイル' }
    desired_listener { 'テスト理想のリスナー' }
    desired_monthly_income { 5000 }
  end
end
