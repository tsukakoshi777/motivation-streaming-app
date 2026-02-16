# frozen_string_literal: true

class GoalsController < ApplicationController
  before_action :require_login
  before_action :set_goal, only: %i[show edit update destroy]

  # 一覧表示
  def index
    @goals = current_user.goals
                         .includes(goal_associations)
                         .order(created_at: :desc)
                         .page(params[:page])
                         .per(4) # 1ページ4件表示
  end

  # 詳細表示
  def show; end

  # 編集画面
  def edit
    # set_goalで@goalが設定済み
  end

  # 更新処理
  def update
    if update_goal_with_nested_attributes
      redirect_to @goal, notice: t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @goal.destroy!
    redirect_to goals_path, notice: t('.success')
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to @goal, alert: t('.failure', error: e.message)
  end

  private

  def set_goal
    @goal = current_user.goals
                        .includes(goal_associations)
                        .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to goals_path
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

  def update_goal_with_nested_attributes
    # survey_resultの更新
    if params[:goal][:survey_result_attributes]
      @goal.survey_profile.survey_result.update(survey_result_params)
    else
      true
    end
  end

  def survey_result_params
    params.require(:goal)
          .require(:survey_result_attributes)
          .permit(:goal_title, :goal_description)
  end
end
