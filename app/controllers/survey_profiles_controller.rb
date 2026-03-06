# frozen_string_literal: true

class SurveyProfilesController < ApplicationController
  before_action :require_login

  def new
    @survey_profile = SurveyProfile.new
    @survey_profile.build_survey_response
    @survey_profile.build_survey_result
    load_select_options
  end

  def create
    @survey_profile = build_survey_profile
    build_associated_records

    if save_all_records
      redirect_to goal_path(@goal), notice: t('.success')
    else
      flash.now[:alert] = t('.failure')
      prepare_for_render

      render :new, status: :unprocessable_entity
    end
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

      redirect_to @goal, notice: t('goals.update.success')
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.debug { "RecordInvalid: #{e.message}" }

    # ビューの表示に必要な変数を設定
    prepare_for_render

    flash.now[:alert] = t('goals.update.failure')
    render :edit, status: :unprocessable_entity
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
      :goal_description
    ).tap do |whitelisted|
      # goal_source を整数に変換
      whitelisted[:goal_source] = whitelisted[:goal_source].to_i if whitelisted[:goal_source].present?
    end
  end
end
