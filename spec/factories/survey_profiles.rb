FactoryBot.define do
  factory :survey_profile do
    association :user
    association :goal
    
    platform { 'YouTube' }
    category { 'ゲーム実況' }
    experience { '初心者' }
    frequency { '週3回' }
    listener_count { 100 }
    streaming_reason { '楽しいから' }
    desired_style { 'エンタメ系' }
    target_income { 10000 }
  end
end