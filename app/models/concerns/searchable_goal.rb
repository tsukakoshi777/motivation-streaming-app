# frozen_string_literal: true

module SearchableGoal
  extend ActiveSupport::Concern

  included do
    scope :search_by_keyword, lambda { |keyword|
      return all if keyword.blank?

      # 複数キーワードをスペースで分割
      keywords = keyword.to_s.strip.split(/\s+/)

      # 各キーワードでOR検索条件を構築
      conditions = []
      values = {}

      keywords.each_with_index do |word, index|
        # SQLインジェクション対策としてサニタイズ
        sanitized_word = ActiveRecord::Base.sanitize_sql_like(word)

        # 各キーワードに対する検索条件を追加
        conditions << "(survey_results.goal_title ILIKE :word#{index} OR " \
                      "survey_results.goal_description ILIKE :word#{index} OR " \
                      "survey_results.ai_goal_suggestion ILIKE :word#{index})"

        values[:"word#{index}"] = "%#{sanitized_word}%"
      end

      # WHERE句を構築
      includes(survey_profile: :survey_result)
        .where(conditions.join(' OR '), **values)
        .references(:survey_results)
        .distinct
    }
  end
end
