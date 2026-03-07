# frozen_string_literal: true

class SurveyProfile < ApplicationRecord
  # アソシエーション
  belongs_to :user
  belongs_to :streaming_platform
  belongs_to :streaming_category
  belongs_to :streaming_experience

  # 1対1の関係
  has_one :survey_response, dependent: :destroy
  has_one :survey_result, dependent: :destroy
  has_one :goal, dependent: :destroy, touch: true

  # バリデーション
  validates :weekly_frequency, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :average_listeners, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_listeners, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :motivation_level, presence: true, inclusion: { in: 1..5 }
  validates :listener_dropout_rate, presence: true, inclusion: { in: 0..3 }
end
