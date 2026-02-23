class SparksController < ApplicationController
  before_action :require_login
  before_action :set_goal

  def create
  @spark = current_user.sparks.build(spark_params)
  @spark.goal_id = params[:goal_id]
  @goal = Goal.find(params[:goal_id])

  respond_to do |format|
    if @spark.save
      flash.now[:success] = '✨ 輝きを記録しました！'
      format.turbo_stream
    else
      flash.now[:danger] = '輝きの記録に失敗しました'
      format.turbo_stream { render turbo_stream: turbo_stream.replace("spark_form", partial: "sparks/form", locals: { goal: @goal, spark: @spark }) }
    end
  end
end

  private

  def set_goal
    @goal = current_user.goals.find(params[:goal_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to goals_path, alert: '目標が見つかりませんでした'
  end

  def spark_params
    params.require(:spark).permit(:content)
  end
end
