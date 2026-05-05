# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeminiService, type: :service do
  let!(:streaming_platform) { create(:streaming_platform, name: 'YouTube') }
  let!(:streaming_category) { create(:streaming_category, name: 'ゲーム実況') }
  let!(:streaming_experience) { create(:streaming_experience, name: '1年未満') }

  # survey_profile と survey_response を作成
  let(:survey_profile) do
    SurveyProfile.new(
      streaming_platform: streaming_platform,
      streaming_category: streaming_category,
      streaming_experience: streaming_experience,
      weekly_frequency: 3,
      average_listeners: 10,
      total_listeners: 100,
      listener_dropout_rate: 1,
      motivation_level: 3
    )
  end

  let(:survey_response) do
    SurveyResponse.new(
      happy_moment: 'リスナーさんからコメントをもらえたとき',
      sad_moment: 'リスナーが全然増えない',
      desired_streaming_style: 'みんなでワイワイ楽しめる配信',
      desired_listener: '優しくて楽しい人',
      desired_monthly_income: 50_000,
      streaming_reasons: '稼ぎたい,有名になりたい,友達を作りたい'
    )
  end

  describe '#suggest_streamer_goal' do
    context '正常系' do
      let(:service) { described_class.new }

      before do
        # モックを設定
        allow(service).to receive(:suggest_streamer_goal).and_return(
          {
            goal_title: 'テスト目標',
            goal_description: '# テスト説明',
            action_plan: '# テスト計画'
          }
        )
      end

      it 'AI提案を取得できること' do
        result = service.suggest_streamer_goal(
          survey_profile: survey_profile,
          survey_response: survey_response
        )

        expect(result).to be_a(Hash)
        expect(result).to have_key(:goal_title)
        expect(result).to have_key(:goal_description)
        expect(result).to have_key(:action_plan)
      end

      it '返却される内容がマークダウン形式であること' do
        result = service.suggest_streamer_goal(
          survey_profile: survey_profile,
          survey_response: survey_response
        )

        expect(result[:goal_description]).to match(/^#/)
        expect(result[:action_plan]).to match(/^#/)
      end
    end

    context '異常系' do
      context 'APIエラーが発生した場合' do
        let(:service) { described_class.new }

        before do
          # モックを無効化
          allow(service).to receive(:use_mock?).and_return(false)
          # APIエラーを発生させる
          allow(service).to receive(:generate_text).and_raise(StandardError.new('API Error'))
        end

        it 'ApiError を raise すること' do
          expect do
            service.suggest_streamer_goal(
              survey_profile: survey_profile,
              survey_response: survey_response
            )
          end.to raise_error(GeminiService::ApiError)
        end
      end

      context 'パラメータが不正な場合' do
        let(:service) { described_class.new }

        it '必須パラメータが不足している場合はエラーになること' do
          expect do
            service.suggest_streamer_goal(
              survey_profile: nil,
              survey_response: nil
            )
          end.to raise_error(GeminiService::ApiError)
        end
      end

      context 'ネットワークエラーが発生した場合' do
        let(:service) { described_class.new }

        before do
          # モックを無効化
          allow(service).to receive(:use_mock?).and_return(false)
          # ネットワークエラーを発生させる
          allow(service).to receive(:generate_text).and_raise(SocketError.new('Network Error'))
        end

        it 'ApiError を raise すること' do
          expect do
            service.suggest_streamer_goal(
              survey_profile: survey_profile,
              survey_response: survey_response
            )
          end.to raise_error(GeminiService::ApiError, /Network Error/)
        end
      end

      context '不正なAPIレスポンスが返された場合' do
        let(:service) { described_class.new }

        before do
          # モックを無効化
          allow(service).to receive(:use_mock?).and_return(false)
          # 不正なレスポンスを返す
          allow(service).to receive(:generate_text).and_return(nil)
        end

        it 'ApiError を raise すること' do
          expect do
            service.suggest_streamer_goal(
              survey_profile: survey_profile,
              survey_response: survey_response
            )
          end.to raise_error(GeminiService::ApiError, /目標提案の生成に失敗しました/)
        end
      end

      context 'タイムアウトが発生した場合' do
        let(:service) { described_class.new }

        before do
          # モックを無効化
          allow(service).to receive(:use_mock?).and_return(false)
          # タイムアウトエラーを発生させる
          allow(service).to receive(:generate_text).and_raise(Timeout::Error.new('Request Timeout'))
        end

        it 'ApiError を raise すること' do
          expect do
            service.suggest_streamer_goal(
              survey_profile: survey_profile,
              survey_response: survey_response
            )
          end.to raise_error(GeminiService::ApiError, /Request Timeout/)
        end
      end
    end
  end
end
