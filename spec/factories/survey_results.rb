# frozen_string_literal: true

FactoryBot.define do
  factory :survey_result do
    association :survey_profile

    goal_title { '配信を継続して100人の視聴者を獲得する' }
    goal_description { '毎週3回配信し、視聴者とのコミュニケーションを大切にする' }

    # 他に必要なカラムがあれば追加
    # created_at と updated_at は自動で設定される
  end
end
