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
      load_select_options
      render :new, status: :unprocessable_entity
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
      @survey_profile.save!
      @survey_profile.survey_response.save!
      @survey_profile.survey_result.save!
      @goal = create_goal
      @goal.persisted?
    rescue ActiveRecord::RecordInvalid
      false
    end
  end

  def create_goal
    current_user.goals.create(survey_profile: @survey_profile)
  end

  def build_survey_response
    @survey_profile.build_survey_response(survey_response_params)
  end

  def survey_response_params
    {
      happy_moment: survey_param(:happy_moment),
      sad_moment: survey_param(:sad_moment),
      streaming_reasons: streaming_reasons_value,
      streaming_reasons_other: survey_param(:streaming_reasons_other),
      desired_streaming_style: survey_param(:desired_streaming_style),
      desired_listener: survey_param(:desired_listener),
      desired_monthly_income: survey_param(:desired_monthly_income)
    }
  end

  def survey_param(key)
    params[:survey_profile][key]
  end

  def streaming_reasons_value
    params[:survey_profile][:streaming_reasons]&.join(',') || ''
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
end
