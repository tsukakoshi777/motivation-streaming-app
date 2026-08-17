# frozen_string_literal: true

class SurveyProfilesController < ApplicationController
  include AiErrorHandler

  before_action :require_login
  before_action :check_ai_suggestion_limit, only: [:fetch_ai_suggestion]

  def new
    @survey_profile = SurveyProfile.new
    @survey_profile.build_survey_response
    @survey_profile.build_survey_result
    load_select_options

    #  Userモデルのメソッドを使う
    current_user.reset_ai_suggestion_count_if_needed

    #  AI提案の使用回数とリセット日時を取得
    @ai_suggestion_count = current_user.ai_suggestion_count
    @reset_date = current_user.ai_suggestion_reset_date || Date.current
  end

  def create
    @survey_profile = build_survey_profile
    build_associated_records

    # AI による目標提案を生成(goal_source が ai の場合のみ)
    if params.dig(:survey_result, :goal_source).to_i == SurveyResult.goal_sources[:ai]
      # ★ ジョブを実行してジョブIDを取得
      job = AiSuggestionJob.perform_later(current_user.id, survey_profile_params)

      # ★ ジョブIDをセッションに保存
      session[:ai_suggestion_job_id] = job.job_id

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'ai_suggestion_form',
            partial: 'survey_profiles/ai_suggestion_form',
            locals: {
              job_id: job.job_id,
              goal_title: '', # ← 追加
              goal_description: '', # ← 追加
              action_plan: '', # ← 追加
              remaining_count: current_user.remaining_ai_suggestion_count # ← 追加
            }
          )
        end
        format.html { render :new, status: :unprocessable_entity }
      end
      return
    end

    if save_all_records
      redirect_to goal_path(@goal), notice: t('.success')
    else
      flash.now[:alert] = t('.failure')
      prepare_for_render

      render :new, status: :unprocessable_entity
    end
  end

  # AI提案を取得するアクション（リファクタリング後）
  def fetch_ai_suggestion
    # パラメータを取得
    params_data = fetch_ai_suggestion_params

    # 一時的なオブジェクトを作成
    survey_profile = build_temporary_survey_profile(params_data)
    survey_response = build_temporary_survey_response(params_data)

    # ⭐ ジョブをキューに追加し、ジョブIDを取得
    job = AiSuggestionJob.perform_later(
      current_user.id,
      survey_profile.attributes,
      survey_response.attributes
    )

    # ⭐ ジョブIDをセッションに保存
    session[:ai_suggestion_job_id] = job.job_id

    # ⭐ JSONを返す（ジョブIDを含める）
    render json: {
      status: 'accepted',
      message: 'AI提案を取得中です...',
      job_id: job.job_id # ⭐ 追加
    }, status: :accepted
  end

  def update
    @goal = Goal.find(params[:goal_id])
    @survey_profile = @goal.survey_profile

    # survey_response が存在しない場合は build する
    survey_response = @survey_profile.survey_response || @survey_profile.build_survey_response

    # survey_result が存在しない場合は build する
    survey_result = @survey_profile.survey_result || @survey_profile.build_survey_result

    # パラメータを assign する
    @survey_profile.assign_attributes(survey_profile_params)
    survey_response.assign_attributes(survey_response_params)
    survey_result.assign_attributes(survey_result_params)

    # 各モデルのバリデーションを先にチェック
    valid_profile = @survey_profile.valid?
    valid_response = survey_response.valid?
    valid_result = survey_result.valid?

    # いずれかのバリデーションが失敗した場合
    unless valid_profile && valid_response && valid_result
      # エラーメッセージを集約
      aggregate_errors(survey_response, survey_result)

      # ビューの表示に必要な変数を設定
      prepare_for_render

      flash.now[:alert] = t('goals.update.failure')
      render :edit, status: :unprocessable_entity
      return
    end

    # トランザクションで一括更新
    ActiveRecord::Base.transaction do
      @survey_profile.save!
      survey_response.save!
      survey_result.save!

      redirect_to @goal, notice: t('goals.update.success'), status: :see_other
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.debug { "RecordInvalid: #{e.message}" }

    # ビューの表示に必要な変数を設定
    prepare_for_render

    flash.now[:alert] = t('goals.update.failure')
    render :edit, status: :unprocessable_entity
  end

  # AI提案をキャンセルするアクション
  def cancel_ai_suggestion
    # ⭐ パラメータからジョブIDを取得（優先）
    job_id = params[:job_id]

    # ⭐ パラメータにない場合は、セッションから取得
    job_id ||= session[:ai_suggestion_job_id]

    if job_id
      # ⭐ Redisにキャンセルフラグを保存
      Rails.cache.write("ai_suggestion_cancelled:#{job_id}", true, expires_in: 1.hour)

      # ⭐ セッションからジョブIDを削除
      session.delete(:ai_suggestion_job_id)

      # ⭐ ログを出力（デバッグ用）
      Rails.logger.info "✅ キャンセルフラグをセットしました: #{job_id}"

      render json: { status: 'cancelled' }, status: :ok
    else
      Rails.logger.warn '❌ キャンセルするジョブが見つかりません'
      render json: { error: 'キャンセルするジョブが見つかりません' }, status: :not_found
    end
  end

  private

  def build_survey_profile
    current_user.survey_profiles.build(survey_profile_params)
  end

  def build_associated_records
    build_survey_response
    build_survey_result
  end

  def save_all_records
    ActiveRecord::Base.transaction do
      # 各モデルのバリデーションを先にチェック
      valid_profile = @survey_profile.valid?
      valid_response = @survey_profile.survey_response.valid?
      valid_result = @survey_profile.survey_result.valid?

      # いずれかのバリデーションが失敗した場合
      unless valid_profile && valid_response && valid_result
        # エラーメッセージを集約
        aggregate_errors(@survey_profile.survey_response, @survey_profile.survey_result)

        raise ActiveRecord::Rollback
      end

      @survey_profile.save!
      @survey_profile.survey_response.save!
      @survey_profile.survey_result.save!
      @goal = create_goal
      @goal.persisted?
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.debug { "RecordInvalid: #{e.message}" }
      false
    end
  end

  def create_goal
    current_user.goals.create(survey_profile: @survey_profile)
  end

  def build_survey_response
    @survey_profile.build_survey_response(survey_response_params)
  end

  def build_survey_result
    @survey_profile.build_survey_result(
      goal_title: params.dig(:survey_result, :goal_title),
      goal_description: params.dig(:survey_result, :goal_description),
      action_plan: params.dig(:survey_result, :action_plan),
      goal_source: params.dig(:survey_result, :goal_source).to_i
    )
  end

  def load_select_options
    @streaming_platforms = StreamingPlatform.all
    @streaming_categories = StreamingCategory.all
    @streaming_experiences = StreamingExperience.all
  end

  # エラーメッセージを @survey_profile.errors に集約するメソッド
  def aggregate_errors(survey_response, survey_result)
    # survey_response のエラーメッセージを追加
    survey_response.errors.each do |error|
      @survey_profile.errors.add(:base, error.full_message)
    end

    # survey_result のエラーメッセージを追加
    survey_result.errors.each do |error|
      @survey_profile.errors.add(:base, error.full_message)
    end
  end

  # ビューの表示に必要な変数を設定するメソッド
  def prepare_for_render
    load_select_options
    @streaming_reasons = params[:survey_profile][:streaming_reasons]&.reject(&:blank?) || []

    #  AI提案の残り回数とリセット日時を設定
    @ai_suggestion_count = current_user.ai_suggestion_count
    @reset_date = current_user.ai_suggestion_reset_date
  end

  def survey_profile_params
    params.require(:survey_profile).permit(
      :streaming_platform_id,
      :streaming_category_id,
      :streaming_experience_id,
      :weekly_frequency,
      :average_listeners,
      :total_listeners,
      :listener_dropout_rate,
      :motivation_level
    )
  end

  def survey_response_params
    params.require(:survey_profile).permit(
      :happy_moment,
      :sad_moment,
      :streaming_reasons_other,
      :desired_streaming_style,
      :desired_listener,
      :desired_monthly_income,
      streaming_reasons: []
    ).tap do |whitelisted|
      # チェックボックスの配列を文字列に変換
      if whitelisted[:streaming_reasons].is_a?(Array)
        # 空配列の場合は nil を設定
        whitelisted[:streaming_reasons] = whitelisted[:streaming_reasons].compact_blank.join(',').presence
      elsif whitelisted[:streaming_reasons].nil?
        # パラメータに含まれていない場合も nil を設定
        whitelisted[:streaming_reasons] = nil
      end
    end
  end

  def survey_result_params
    params.require(:survey_result).permit(
      :goal_source,
      :goal_title,
      :goal_description,
      :action_plan
    ).tap do |whitelisted|
      # goal_source を整数に変換
      whitelisted[:goal_source] = whitelisted[:goal_source].to_i if whitelisted[:goal_source].present?
    end
  end

  # AI による目標提案を生成するメソッド
  def generate_ai_goal_suggestion
    service = GeminiService.new
    result = service.suggest_streamer_goal(
      survey_profile: @survey_profile,
      survey_response: @survey_profile.survey_response
    )

    # AI の提案を survey_result に設定
    @survey_profile.survey_result.assign_attributes(
      goal_title: result[:goal_title],
      goal_description: result[:goal_description],
      action_plan: result[:action_plan]
    )
  rescue GeminiService::ApiError => e
    Rails.logger.error "AI goal suggestion generation failed: #{e.message}"
    @survey_profile.errors.add(:base, t('survey_profiles.create.ai_generation_failed'))
    raise ActiveRecord::Rollback
  end

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
