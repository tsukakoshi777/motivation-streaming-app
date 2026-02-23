# frozen_string_literal: true

class Goal < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :survey_profile
  has_one :survey_result, through: :survey_profile
  has_many :sparks, dependent: :destroy

  # survey_profile を通じて survey_response にアクセスできるようにする
  delegate :survey_response, to: :survey_profile

  # バリデーション
  validates :survey_profile_id, uniqueness: true
end
