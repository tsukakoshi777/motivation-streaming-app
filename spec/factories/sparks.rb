# frozen_string_literal: true

FactoryBot.define do
  factory :spark do
    content { '今日も頑張ろう！' }
    association :goal
    association :user # ⭐ user の関連付けを追加
  end
end
