# frozen_string_literal: true

class StreamingExperience < ApplicationRecord
  has_many :survey_profiles, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
