# frozen_string_literal: true

class SurveyResponse < ApplicationRecord
  # アソシエーション
  belongs_to :survey_profile

  # バリデーション
  validates :survey_profile_id, uniqueness: true
end
