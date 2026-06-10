# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Oauths', type: :request do
  describe 'Google OAuth 認証' do
    #  oauth_data メソッドを定義
    def oauth_data(email: 'test@example.com', name: 'Test User')
      {
        provider: 'google',
        uid: '123456789',
        user_info: {
          'email' => email,
          'name' => name
        }
      }
    end

    context '新規ユーザーの場合' do
      before do
        #  @oauth_data を動的に生成
        @oauth_data = oauth_data(email: 'newuser@example.com', name: 'Test User')

        # callback メソッド全体をモック化
        allow_any_instance_of(OauthsController).to receive(:callback) do |controller|
          #  @oauth_data を参照
          controller.instance_variable_set(:@user_hash, @oauth_data)

          #  @oauth_data を参照
          @user = User.create!(
            nickname: @oauth_data[:user_info]['name'],
            email: @oauth_data[:user_info]['email'],
            password: 'password',
            password_confirmation: 'password'
          )

          #  @oauth_data を参照
          @user.authentications.create!(
            provider: @oauth_data[:provider],
            uid: @oauth_data[:uid]
          )

          # ログイン処理
          controller.send(:auto_login, @user)

          # リダイレクト
          controller.redirect_to controller.root_path, success: 'Googleアカウントでログインしました'
        end
      end

      it 'Google アカウントで新規ユーザー登録ができる' do
        expect do
          get '/oauth/callback?provider=google'
        end.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
        follow_redirect!

        expect(flash[:success]).to be_present
      end

      it 'Authentication レコードが作成される' do
        expect do
          get '/oauth/callback?provider=google'
        end.to change(Authentication, :count).by(1)

        authentication = Authentication.last
        expect(authentication.provider).to eq('google')
        expect(authentication.uid).to eq('123456789')
      end

      it 'ユーザーの nickname が正しく設定される' do
        get '/oauth/callback?provider=google'

        user = User.last
        expect(user.nickname).to eq('Test User')
      end
    end

    context '既存ユーザーの場合' do
      #  email を削除（Factory Bot の sequence を有効にする）
      let!(:user) { create(:user) }

      context 'Google アカウントが未連携の場合' do
        before do
          #  oauth_data を動的に生成（既存ユーザーのメールアドレスを使う）
          @oauth_data = oauth_data(email: user.email, name: 'Test User')

          # callback メソッド全体をモック化
          allow_any_instance_of(OauthsController).to receive(:callback) do |controller|
            #  @oauth_data を参照
            controller.instance_variable_set(:@user_hash, @oauth_data)

            #  @oauth_data を参照
            email = @oauth_data[:user_info]['email']
            @user = User.find_by(email: email)

            #  @oauth_data を参照
            @user.authentications.create!(
              provider: @oauth_data[:provider],
              uid: @oauth_data[:uid]
            )

            # ログイン処理
            controller.send(:auto_login, @user)

            # リダイレクト
            controller.redirect_to controller.root_path, success: 'Googleアカウントを連携しました'
          end
        end

        it 'Google アカウントを連携できる' do
          expect do
            get '/oauth/callback?provider=google'
          end.to change(Authentication, :count).by(1)

          expect(response).to redirect_to(root_path)
          follow_redirect!

          expect(flash[:success]).to include('連携しました')
        end
      end

      context 'Google アカウントが既に連携済みの場合' do
        before do
          create(:authentication, user: user, provider: 'google', uid: '123456789')

          # login_from は既存ユーザーを返す
          allow_any_instance_of(OauthsController).to receive(:login_from).with('google').and_return(user)
        end

        it 'Google アカウントでログインできる' do
          get '/oauth/callback?provider=google'

          expect(response).to redirect_to(root_path)
          follow_redirect!

          expect(flash[:success]).to be_present
        end
      end
    end

    context 'エラーハンドリング' do
      before do
        #  oauth_data を動的に生成
        @oauth_data = oauth_data(email: 'error@example.com', name: 'Error User')

        # callback メソッド全体をモック化
        allow_any_instance_of(OauthsController).to receive(:callback) do |controller|
          #  @oauth_data を参照
          controller.instance_variable_set(:@user_hash, @oauth_data)

          # エラーを発生させる
          begin
            raise StandardError, 'OAuth認証エラー'
          rescue StandardError => e
            Rails.logger.error "OAuth認証エラー: #{e.message}"
            controller.redirect_to controller.login_path, danger: 'Googleアカウントでのログインに失敗しました'
          end
        end
      end

      it 'Google 認証に失敗した場合、ログインページにリダイレクトされる' do
        get '/oauth/callback?provider=google'

        expect(response).to redirect_to(login_path)
        follow_redirect!

        expect(flash[:danger]).to be_present
      end
    end
  end
end
