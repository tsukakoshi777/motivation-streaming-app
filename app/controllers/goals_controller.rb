# frozen_string_literal: true

class GoalsController < ApplicationController
  before_action :require_login

  def show
    @goal = find_goal_with_associations
    authorize_goal_access!
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t('.not_found')
  end

  private

  def find_goal_with_associations
    Goal.includes(goal_associations).find(params[:id])
  end

  def goal_associations
    {
      survey_profile: %i[
        streaming_platform
        streaming_category
        streaming_experience
        survey_response
        survey_result
      ]
    }
  end

  def authorize_goal_access!
    return if @goal.user_id == current_user.id

    redirect_to root_path, alert: t('.access_denied')
  end
end
