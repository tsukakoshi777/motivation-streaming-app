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
      before do
        allow_any_instance_of(GeminiService).to receive(:suggest_streamer_goal).and_return(
          {
            goal_title: 'テスト目標',
            goal_description: '# テスト説明',
            action_plan: '# テスト計画'
          }
        )
      end

      it 'AI提案を取得できること' do
        post fetch_ai_suggestion_survey_profiles_path, params: valid_params

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json['goal_title']).to eq('テスト目標')
        expect(json['goal_description']).to eq('# テスト説明')
        expect(json['action_plan']).to eq('# テスト計画')
      end
    end

    context '異常系' do
      # パラメータが不足していてもAI提案を返すことを確認
      context 'パラメータが不足している場合' do
        before do
          allow_any_instance_of(GeminiService).to receive(:suggest_streamer_goal).and_return(
            {
              goal_title: 'デフォルト目標',
              goal_description: '# デフォルト説明',
              action_plan: '# デフォルト計画'
            }
          )
        end

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

          expect(response).to have_http_status(:success)
          json = response.parsed_body
          expect(json['goal_title']).to eq('デフォルト目標')
          expect(json['goal_description']).to eq('# デフォルト説明')
          expect(json['action_plan']).to eq('# デフォルト計画')
        end
      end

      # APIエラーのテストケースを追加
      context 'APIエラーが発生した場合' do
        before do
          allow_any_instance_of(GeminiService)
            .to receive(:suggest_streamer_goal)
            .and_raise(GeminiService::ApiError.new('API Error'))
        end

        it 'エラーレスポンスが返ること' do
          post fetch_ai_suggestion_survey_profiles_path, params: valid_params

          expect(response).to have_http_status(:internal_server_error)
          json = response.parsed_body
          expect(json['error']).to eq('AI提案の取得に失敗しました')
        end
      end
    end
  end
end
