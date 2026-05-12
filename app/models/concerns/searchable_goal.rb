# frozen_string_literal: true

module SearchableGoal
  extend ActiveSupport::Concern

  included do
    scope :search_by_keyword, lambda { |keyword|
      return all if keyword.blank?

      # joins を includes + references に置き換える
      includes(survey_profile: :survey_result)
        .where(
          'survey_results.goal_title ILIKE :keyword OR
           survey_results.goal_description ILIKE :keyword OR
           survey_results.ai_goal_suggestion ILIKE :keyword',
          keyword: "%#{keyword}%"
        )
        .references(:survey_results)
        .distinct
    }
  end
end
