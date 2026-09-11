# frozen_string_literal: true

module AiSuggestionManagement
  extend ActiveSupport::Concern

  included do
    before_action :check_ai_suggestion_limit, only: [:fetch_ai_suggestion]
  end

  # AI提案を取得するアクション(リファクタリング後)
  def fetch_ai_suggestion
    # パラメータを取得
    params_data = fetch_ai_suggestion_params

    # 一時的なオブジェクトを作成
    survey_profile = build_temporary_survey_profile(params_data)
    survey_response = build_temporary_survey_response(params_data)

    # ジョブIDを事前に生成
    job_id = SecureRandom.uuid

    # ジョブIDをセッションに保存
    session[:ai_suggestion_job_id] = job_id

    # ジョブを実行する直前にログを出力
    Rails.logger.info 'AiSuggestionJob.perform_later を呼び出します'
    Rails.logger.info "引数: user_id=#{current_user.id}, survey_profile=#{survey_profile.attributes},
    survey_response=#{survey_response.attributes}, job_id=#{job_id}"

    # ジョブIDをパラメータとして渡す
    AiSuggestionJob.perform_later(
      current_user.id,
      survey_profile.attributes,
      survey_response.attributes,
      job_id # ← ジョブIDを追加
    )

    Rails.logger.info "✅ ジョブを開始しました: #{job_id}"
    Rails.logger.info '========== fetch_ai_suggestion 終了 =========='

    # JSONを返す(ジョブIDを含める)
    render json: {
      status: 'accepted',
      message: 'AI提案を取得中です...',
      job_id: job_id
    }, status: :accepted
  rescue StandardError => e
    Rails.logger.error "❌ エラーが発生しました: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    render json: { error: e.message }, status: :internal_server_error
  end

  def cancel_ai_suggestion
    # セッションから最新のジョブIDを取得
    job_id = session[:ai_suggestion_job_id]

    if job_id.present?
      # Redisにキャンセルフラグを保存
      Rails.cache.write("ai_suggestion_cancelled:#{job_id}", true, expires_in: 1.hour)

      # ログを出力(デバッグ用)
      Rails.logger.info "✅ キャンセルフラグをセットしました: #{job_id}"

      render json: { status: 'cancelled' }, status: :ok
    else
      Rails.logger.warn '❌ キャンセルするジョブが見つかりません'
      render json: { error: 'キャンセルするジョブが見つかりません' }, status: :not_found
    end
  end

  private

  # fetch_ai_suggestion 用のパラメータ取得
  def fetch_ai_suggestion_params
    params.permit(
      :streaming_platform_id,
      :streaming_category_id,
      :streaming_experience_id,
      :weekly_frequency,
      :average_listeners,
      :total_listeners,
      :listener_dropout_rate,
      :motivation_level,
      :happy_moment,
      :sad_moment,
      :desired_streaming_style,
      :desired_listener,
      :desired_monthly_income,
      :streaming_reasons_other,
      streaming_reasons: []
    )
  end

  # 一時的な survey_profile を作成（保存しない）
  def build_temporary_survey_profile(params_data)
    SurveyProfile.new(
      user_id: current_user.id,
      streaming_platform_id: params_data[:streaming_platform_id],
      streaming_category_id: params_data[:streaming_category_id],
      streaming_experience_id: params_data[:streaming_experience_id],
      weekly_frequency: params_data[:weekly_frequency],
      average_listeners: params_data[:average_listeners],
      total_listeners: params_data[:total_listeners],
      listener_dropout_rate: params_data[:listener_dropout_rate],
      motivation_level: params_data[:motivation_level]
    )
  end

  # 一時的な survey_response を作成（保存しない）
  def build_temporary_survey_response(params_data)
    SurveyResponse.new(
      happy_moment: params_data[:happy_moment],
      sad_moment: params_data[:sad_moment],
      desired_streaming_style: params_data[:desired_streaming_style],
      desired_listener: params_data[:desired_listener],
      desired_monthly_income: params_data[:desired_monthly_income],
      streaming_reasons: params_data[:streaming_reasons]&.compact_blank&.join(','),
      streaming_reasons_other: params_data[:streaming_reasons_other]
    )
  end

  # Gemini Service から AI提案を取得
  def fetch_suggestion_from_gemini(survey_profile, survey_response)
    gemini_service = GeminiService.new
    gemini_service.suggest_streamer_goal(
      survey_profile: survey_profile,
      survey_response: survey_response
    )
  end

  #  AI提案の利用回数制限をチェック（Userモデルのメソッドを使う）
  def check_ai_suggestion_limit
    # 日付が変わっていたらカウントをリセット
    current_user.reset_ai_suggestion_count_if_needed

    return if current_user.can_use_ai_suggestion?

    render json: {
      error: t('survey_profiles.errors.ai_suggestion_limit_reached')
    }, status: :forbidden
  end
end
