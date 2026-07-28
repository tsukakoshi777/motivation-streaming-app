# frozen_string_literal: true

class AiSuggestionJob < ApplicationJob
  queue_as :default

  def perform(user_id, survey_profile_attrs, survey_response_attrs)
    user = User.find(user_id)

    # 一時的なオブジェクトを作成
    survey_profile = SurveyProfile.new(survey_profile_attrs)
    survey_response = SurveyResponse.new(survey_response_attrs)

    # Gemini API を呼び出して、AI の提案を取得
    gemini_service = GeminiService.new
    suggestion = gemini_service.suggest_streamer_goal(
      survey_profile: survey_profile,
      survey_response: survey_response
    )

    # AI提案の使用回数をインクリメント
    user.increment_ai_suggestion_count

    # 残り回数を計算
    remaining_count = user.remaining_ai_suggestion_count

    # ★ Turbo Frame 全体を置き換える
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user.id}",
      target: 'ai_suggestion_form', # ← Turbo Frame の ID
      partial: 'survey_profiles/ai_suggestion_form',
      locals: {
        goal_title: suggestion[:goal_title],
        goal_description: suggestion[:goal_description],
        action_plan: suggestion[:action_plan],
        remaining_count: remaining_count
      }
    )
  rescue GeminiService::ApiError => e
    Rails.logger.error("AI suggestion generation failed: #{e.message}")

    # ★ エラー時も Turbo Frame 全体を置き換える
    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user.id}",
      target: 'ai_suggestion_form', # ← Turbo Frame の ID
      partial: 'survey_profiles/ai_suggestion_error',
      locals: { error_message: e.message }
    )
  end
end
