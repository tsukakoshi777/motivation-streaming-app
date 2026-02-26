class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, success: 'プロフィールを更新しました'
    else
      flash.now[:danger] = 'プロフィールの更新に失敗しました'
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:nickname, :email, :avatar, :avatar_cache, :remove_avatar)
  end
end