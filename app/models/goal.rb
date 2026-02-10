# frozen_string_literal: true

class Goal < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :survey_profile

  # バリデーション
  validates :survey_profile_id, uniqueness: true
end
