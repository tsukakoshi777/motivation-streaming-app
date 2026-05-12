# frozen_string_literal: true

class Goal < ApplicationRecord
  include SearchableGoal

  # アソシエーション
  belongs_to :user
  belongs_to :survey_profile, dependent: :destroy

  # SurveyProfile を経由して関連データにアクセス
  has_one :survey_result, through: :survey_profile
  has_many :sparks, dependent: :destroy
  has_one :survey_response, through: :survey_profile

  # バリデーション
  validates :survey_profile_id, uniqueness: true
end
