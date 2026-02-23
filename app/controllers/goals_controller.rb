# frozen_string_literal: true

class GoalsController < ApplicationController
  before_action :require_login
  before_action :set_goal, only: %i[show edit update destroy]

  def index
    @goals = current_user.goals
                         .includes(goal_associations)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(4)
  end

  def show
    @streaming_reasons = @goal.survey_profile&.survey_response&.streaming_reasons&.split(',') || []
  end

  def edit
    # 編集画面用のデータを準備
    @survey_profile = @goal.survey_profile
    load_select_options

    # streaming_reasons を配列に変換
    @streaming_reasons = @survey_profile&.survey_response&.streaming_reasons&.split(',') || []
  end

  def destroy
    @goal.destroy!
    redirect_to goals_path, notice: t('.success')
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to @goal, alert: t('.failure')
  end

  private

  def set_goal
    @goal = current_user.goals
                        .includes(goal_associations)
                        .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to goals_path, alert: t('goals.show.not_found')
  end

  def goal_associations
    {
      survey_profile: %i[
        streaming_platform
        streaming_category
        streaming_experience
        survey_response
        survey_result
      ],
      sparks: :user
    }
  end

  def load_select_options
    @streaming_platforms = StreamingPlatform.all
    @streaming_categories = StreamingCategory.all
    @streaming_experiences = StreamingExperience.all
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
      :desired_streaming_style,
      :desired_listener,
      :desired_monthly_income,
      :streaming_reasons_other,
      streaming_reasons: []
    )
  end

  def survey_result_params
    params.require(:survey_result).permit(
      :goal_source,
      :goal_title,
      :goal_description
    )
  end
end
