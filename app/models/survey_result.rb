# frozen_string_literal: true

class SurveyResult < ApplicationRecord
  # enum
  enum :goal_source, { ai_suggestion: 0, user_defined: 1 }

  # アソシエーション
  belongs_to :survey_profile, touch: true

  # バリデーション
  validates :survey_profile_id, uniqueness: true
  validates :goal_source, presence: true
end
