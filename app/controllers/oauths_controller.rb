# frozen_string_literal: true

class OauthsController < ApplicationController
  skip_before_action :require_login

  # OAuth 認証を開始
  def oauth
    provider = params[:provider]

    # Google 以外は拒否
    unless provider == 'google'
      redirect_to login_path, danger: t('oauths.invalid_provider')
      return
    end

    # Sorcery の login_at メソッドで Google 認証 URL を取得
    login_at(provider)
  end

  # OAuth 認証後のコールバック
  def callback
    provider = params[:provider]
    provider_name = provider&.titleize || 'OAuth'

    # 既存のユーザーでログイン
    if (@user = login_from(provider))
      redirect_to root_path, success: t('oauths.login_success', provider: provider_name)
    else
      # OAuth 情報を取得（@user_hash を使用）
      user_info = @user_hash
      email = user_info[:user_info]['email']

      # メールアドレスが一致する既存ユーザーを検索
      @user = User.find_by(email: email)

      if @user
        # 既存ユーザーと Google アカウントを紐付ける
        @user.authentications.create!(
          provider: provider,
          uid: user_info[:uid]
        )
        auto_login(@user)
        redirect_to root_path, success: t('oauths.link_success', provider: provider_name)
      else
        # 新規ユーザーを作成してログイン
        begin
          @user = create_from(provider)
          reset_session
          auto_login(@user)
          redirect_to root_path, success: t('oauths.login_success', provider: provider_name)
        rescue StandardError => e
          Rails.logger.error "OAuth認証エラー: #{e.message}"
          redirect_to login_path, danger: t('oauths.login_failed', provider: provider_name)
        end
      end
    end
  end
end
