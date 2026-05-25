# frozen_string_literal: true

class SparksController < ApplicationController
  before_action :require_login
  before_action :set_goal
  before_action :set_spark, only: %i[edit update cancel destroy]

  def edit
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to goal_path(@goal) } # HTML リクエストの場合はリダイレクト
    end
  end

  def create
    @spark = current_user.sparks.build(spark_params)
    @spark.goal_id = params[:goal_id]

    respond_to do |format|
      if @spark.save
        # ページネーションを考慮して @sparks を再取得（1ページ目を表示）
        @sparks = @goal.sparks
                       .includes(:user)
                       .order(created_at: :desc)
                       .page(1)
                       .per(5)
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
    @spark.update(spark_params)

    # 現在のページを維持
    @sparks = @goal.sparks
                   .includes(:user)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(4)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def cancel
    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @spark = @goal.sparks.find(params[:id])
    @spark.destroy!

    # 削除後の輝き一覧を取得
    current_page = params[:page].to_i
    current_page = 1 if current_page < 1

    @sparks = @goal.sparks
                   .includes(:user)
                   .order(created_at: :desc)
                   .page(current_page)
                   .per(4)

    # デバッグ用
    puts '========== デバッグ情報 =========='
    puts "params[:page]: #{params[:page]}"
    puts "current_page: #{current_page}"
    puts "@sparks.size: #{@sparks.size}"
    puts "@sparks.empty?: #{@sparks.empty?}"
    puts "current_page > 1: #{current_page > 1}"
    puts "条件: #{@sparks.empty? && current_page > 1}"

    # 削除後に現在のページが空になった場合は前のページを表示
    if @sparks.empty? && current_page > 1
      puts '========== 前のページを取得 =========='
      # 前のページを取得
      current_page -= 1
      @sparks = @goal.sparks
                     .includes(:user)
                     .order(created_at: :desc)
                     .page(current_page)
                     .per(4)
      puts "新しい current_page: #{current_page}"
      puts "新しい @sparks.size: #{@sparks.size}"
    end

    # ページ番号を保存
    @current_page = current_page
    puts "@current_page: #{@current_page}"
    puts '================================='

    flash.now[:success] = t('.success')

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_goal
    @goal = current_user.goals.find(params[:goal_id]) # ← includes を削除
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Goal not found: #{params[:goal_id]} for user: #{current_user.id}")
    redirect_to goals_path, alert: t('goals.show.not_found')
  end

  def set_spark
    @spark = @goal.sparks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Spark not found: #{params[:id]} for goal: #{@goal&.id}")
    redirect_to goal_path(@goal), alert: t('sparks.not_found')
  end

  def spark_params
    params.require(:spark).permit(:content)
  end
end
