# frozen_string_literal: true

class AiSuggestionJob < ApplicationJob
  queue_as :default

  def perform(user_id, survey_profile_attrs, survey_response_attrs, job_id)
    # デバッグログを追加
    Rails.logger.info "✅ ジョブを開始しました: #{job_id}"

    # キャンセルチェック: ジョブ開始時
    return if cancelled_early?(job_id, 'before starting')

    user = User.find(user_id)
    survey_profile, survey_response = build_survey_objects(survey_profile_attrs, survey_response_attrs)

    # キャンセルチェック: API呼び出し前
    return if cancelled_early?(job_id, 'before API call')

    suggestion = fetch_ai_suggestion(survey_profile, survey_response)

    # キャンセルチェック: API呼び出し後
    return if cancelled_early?(job_id, 'after API call')

    broadcast_success(user, suggestion, job_id) # ← job_id を渡す
  rescue GeminiService::ApiError => e
    handle_api_error(user_id, e)
  end

  private

  # キャンセルフラグをチェックし、キャンセルされていればログを出力
  def cancelled_early?(job_id, stage)
    return false unless cancelled?(job_id)

    Rails.logger.info "Job #{job_id} was cancelled #{stage}"
    true
  end

  # キャンセルフラグをチェックするメソッド
  def cancelled?(job_id)
    Rails.cache.read("ai_suggestion_cancelled:#{job_id}").present?
  end

  # 一時的なオブジェクトを作成
  def build_survey_objects(survey_profile_attrs, survey_response_attrs)
    survey_profile = SurveyProfile.new(survey_profile_attrs)
    survey_response = SurveyResponse.new(survey_response_attrs)
    [survey_profile, survey_response]
  end

  # Gemini API を呼び出して、AI の提案を取得
  def fetch_ai_suggestion(survey_profile, survey_response)
    gemini_service = GeminiService.new
    gemini_service.suggest_streamer_goal(
      survey_profile: survey_profile,
      survey_response: survey_response
    )
  end

  # 成功時のTurbo Stream配信
  def broadcast_success(user, suggestion, job_id)
    user.increment_ai_suggestion_count
    remaining_count = user.remaining_ai_suggestion_count

    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user.id}",
      target: 'ai_suggestion_form',
      partial: 'survey_profiles/ai_suggestion_form',
      locals: {
        job_id: job_id,
        goal_title: suggestion[:goal_title],
        goal_description: suggestion[:goal_description],
        action_plan: suggestion[:action_plan],
        remaining_count: remaining_count
      }
    )
  end

  # エラー時の処理
  def handle_api_error(user_id, error)
    Rails.logger.error("AI suggestion generation failed: #{error.message}")

    Turbo::StreamsChannel.broadcast_replace_to(
      "user_#{user_id}",
      target: 'ai_suggestion_form',
      partial: 'survey_profiles/ai_suggestion_error',
      locals: { error_message: 'AI提案の取得に失敗しました。もう一度お試しください。' }
    )
  end
end
