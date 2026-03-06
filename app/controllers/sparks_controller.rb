# frozen_string_literal: true

class SparksController < ApplicationController
  before_action :require_login
  before_action :set_goal
  before_action :set_spark, only: %i[edit update destroy]

  def edit
    @goal = current_user.goals.find(params[:goal_id])
    @spark = @goal.sparks.find(params[:id])

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to goal_path(@goal) } # HTML リクエストの場合はリダイレクト
    end
  end

  def create
    @spark = current_user.sparks.build(spark_params)
    @spark.goal_id = params[:goal_id]
    @goal = Goal.find(params[:goal_id])

    respond_to do |format|
      if @spark.save
        # flash.now[:success] = t('sparks.create.success')
        format.turbo_stream
      else
        # flash.now[:danger] = t('sparks.create.failure')
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('spark_form', partial: 'sparks/form',
                                                                  locals: { goal: @goal, spark: @spark })
        end
      end
    end
  end

  def update
    @goal = current_user.goals.find(params[:goal_id])
    @spark = @goal.sparks.find(params[:id])

    @spark.update(spark_params)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def cancel
    @goal = current_user.goals.find(params[:goal_id])
    @spark = @goal.sparks.find(params[:id])

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @spark.destroy
    respond_to do |format|
      flash.now[:success] = t('.success')
      format.turbo_stream
    end
  end

  private

  def set_goal
    @goal = current_user.goals.find(params[:goal_id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Goal not found: #{params[:goal_id]} for user: #{current_user.id}")
  end

  def set_spark
    @spark = @goal.sparks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Spark not found: #{params[:id]} for goal: #{@goal&.id}")
  end

  def spark_params
    params.require(:spark).permit(:content)
  end
end
