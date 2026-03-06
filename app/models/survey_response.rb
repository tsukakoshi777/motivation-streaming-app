# frozen_string_literal: true

class SurveyResponse < ApplicationRecord
  # アソシエーション
  belongs_to :survey_profile

  # バリデーション
  validates :survey_profile_id, uniqueness: true
  validate :streaming_reasons_count

  private

  def streaming_reasons_count
    return if streaming_reasons.blank?

    reasons_array = streaming_reasons.split(',').map(&:strip).compact_blank

    return unless reasons_array.length > 3

    errors.add(:streaming_reasons, 'は3つまで選択してください')
  end
end
