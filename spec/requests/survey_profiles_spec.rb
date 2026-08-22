# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SurveyProfiles', type: :request do
  let!(:user) { create(:user) }
  let!(:streaming_platform) { create(:streaming_platform, name: 'YouTube') }
  let!(:streaming_category) { create(:streaming_category, name: 'ゲーム実況') }
  let!(:streaming_experience) { create(:streaming_experience, name: '1年未満') }

  before do
    login_as(user)
  end

  describe 'POST /survey_profiles/fetch_ai_suggestion' do
    let(:valid_params) do
      {
        streaming_platform_id: streaming_platform.id,
        streaming_category_id: streaming_category.id,
        streaming_experience_id: streaming_experience.id,
        weekly_frequency: 3,
        average_listeners: 10,
        total_listeners: 100,
        listener_dropout_rate: 1,
        motivation_level: 3,
        happy_moment: 'リスナーさんからコメントをもらえたとき',
        sad_moment: 'リスナーが全然増えない',
        desired_streaming_style: 'みんなでワイワイ楽しめる配信',
        desired_listener: '優しくて楽しい人',
        desired_monthly_income: 50_000,
        streaming_reasons: %w[稼ぎたい 有名になりたい 友達を作りたい]
      }
    end

    context '正常系' do
      # ⭐ ジョブを同期的に実行するように設定
      before do
        ActiveJob::Base.queue_adapter = :test
      end

      it 'AI提案を取得できること' do
        # ⭐ デバッグ用ログ
        puts "\n========== デバッグ開始 =========="
        puts 'Before post:'
        puts "  user.id: #{user.id}"
        puts "  user.ai_suggestion_count: #{user.ai_suggestion_count}"
        puts "  user.can_use_ai_suggestion?: #{user.can_use_ai_suggestion?}"
        puts "  valid_params: #{valid_params.inspect}"

        # ⭐ perform_enqueued_jobs ブロック内でリクエストを送信
        perform_enqueued_jobs do
          post fetch_ai_suggestion_survey_profiles_path, params: valid_params
        end

        # ⭐ デバッグ用ログ
        puts "\nAfter post:"
        puts "  response.status: #{response.status}"
        puts "  response.body: #{response.body}"
        puts "========== デバッグ終了 ==========\n"

        # ⭐ レスポンスを確認
        expect(response).to have_http_status(:accepted)
        json = response.parsed_body
        expect(json['status']).to eq('accepted')
        expect(json['message']).to eq('AI提案を取得中です...')
        expect(json['job_id']).to be_present

        # ⭐ ジョブが自動的に実行されるため、カウントが増えている
        user.reload
        expect(user.ai_suggestion_count).to eq(1)
      end

      it 'AI提案を3回まで利用できること' do
        # ⭐ perform_enqueued_jobs ブロック内でリクエストを送信
        perform_enqueued_jobs do
          3.times do
            post fetch_ai_suggestion_survey_profiles_path, params: valid_params

            expect(response).to have_http_status(:accepted)
            json = response.parsed_body
            expect(json['status']).to eq('accepted')
            expect(json['message']).to eq('AI提案を取得中です...')
            expect(json['job_id']).to be_present
          end
        end

        # カウントが3になっていることを確認
        user.reload
        expect(user.ai_suggestion_count).to eq(3)
      end

      it '日付が変わった後、カウントがリセットされること' do
        # ⭐ perform_enqueued_jobs ブロック内でリクエストを送信
        perform_enqueued_jobs do
          # 3回AI提案を利用
          3.times do
            post fetch_ai_suggestion_survey_profiles_path, params: valid_params
          end
        end

        # カウントが3になっていることを確認
        user.reload
        expect(user.ai_suggestion_count).to eq(3)

        # 日付を昨日に変更
        user.update!(ai_suggestion_reset_date: Date.yesterday)

        # ⭐ perform_enqueued_jobs ブロック内でリクエストを送信
        perform_enqueued_jobs do
          # 再度AI提案を利用
          post fetch_ai_suggestion_survey_profiles_path, params: valid_params
        end

        expect(response).to have_http_status(:accepted)
        json = response.parsed_body
        expect(json['status']).to eq('accepted')

        # カウントがリセットされ、1にカウントされていることを確認
        user.reload
        expect(user.ai_suggestion_count).to eq(1)
        expect(user.ai_suggestion_reset_date).to eq(Date.current)
      end
    end

    context '異常系' do
      context 'パラメータが不足している場合' do
        let(:minimal_params) do
          {
            streaming_platform_id: streaming_platform.id,
            streaming_category_id: streaming_category.id,
            streaming_experience_id: streaming_experience.id,
            weekly_frequency: '',
            average_listeners: '',
            total_listeners: '',
            listener_dropout_rate: '',
            motivation_level: '',
            happy_moment: '',
            sad_moment: '',
            desired_streaming_style: '',
            desired_listener: '',
            desired_monthly_income: '',
            streaming_reasons: []
          }
        end

        it '最小限のパラメータでもAI提案を返すこと' do
          post fetch_ai_suggestion_survey_profiles_path, params: minimal_params

          # ⭐ レスポンスを確認
          expect(response).to have_http_status(:accepted)
          json = response.parsed_body
          expect(json['status']).to eq('accepted')
          expect(json['message']).to eq('AI提案を取得中です...')
          expect(json['job_id']).to be_present
        end
      end

      context 'APIエラーが発生した場合' do
        # ⭐ このテストは削除または変更が必要
        # 理由: 非同期処理に変更したため、エラーはジョブ内で発生する
        # コントローラではエラーが発生しない
      end

      context '3回制限に達した場合' do
        before do
          # ユーザーのカウントを3に設定
          user.update!(ai_suggestion_count: 3, ai_suggestion_reset_date: Date.current)
        end

        it '403 Forbidden が返されること' do
          post fetch_ai_suggestion_survey_profiles_path, params: valid_params

          expect(response).to have_http_status(:forbidden)
          json = response.parsed_body
          expect(json['error']).to eq('AI提案の利用回数が上限（3回）に達しました。自分で設定する方法で目標を作成してください。')
        end
      end
    end
  end
end
