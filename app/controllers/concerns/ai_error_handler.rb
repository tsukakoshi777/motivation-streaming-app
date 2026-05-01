# frozen_string_literal: true

module AiErrorHandler
  extend ActiveSupport::Concern

  private

  # レート制限エラーのハンドリング
  def handle_rate_limit_error(error)
    Rails.logger.error "AI suggestion rate limit exceeded: #{error.message}"
    render json: {
      error: t('survey_profiles.errors.rate_limit_exceeded')
    }, status: :too_many_requests
  end

  # 不正なレスポンスエラーのハンドリング
  def handle_invalid_response_error(error)
    Rails.logger.error "AI suggestion invalid response: #{error.message}"
    render json: {
      error: t('survey_profiles.errors.invalid_response')
    }, status: :internal_server_error
  end

  # Gemini API エラーのハンドリング
  def handle_gemini_error(error)
    Rails.logger.error "AI suggestion fetch failed: #{error.message}"
    render json: { error: t('survey_profiles.errors.ai_suggestion_fetch_failed') }, status: :internal_server_error
  end
end
