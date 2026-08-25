# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SurveyProfiles', type: :system do
  let(:user) { create(:user) }
  let!(:streaming_platform) { create(:streaming_platform, name: 'YouTube') }
  let!(:streaming_category) { create(:streaming_category, name: 'ゲーム実況') }
  let!(:streaming_experience) { create(:streaming_experience, name: '初心者(1ヶ月未満)') }

  # ⭐ ここに配置（before ブロックの前）
  before do
    ActiveJob::Base.queue_adapter = :test
  end

  before do
    # ログイン処理
    visit login_path

    # ログインページが表示されるまで待機
    expect(page).to have_content('ログイン'), 'ログインページが表示されません'

    # フォームのフィールド名を確認
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password'

    click_button 'ログイン'

    # ログイン成功を確認
    expect(page).to have_content('ログインしました'), 'ログインに失敗しました'
  end

  describe 'AI提案機能' do
    context '正常系' do
      it 'アンケートフォームからAI提案を取得できること', js: true do
        # スタブを正確に設定
        gemini_service_mock = instance_double(GeminiService)
        allow(GeminiService).to receive(:new).and_return(gemini_service_mock)
        allow(gemini_service_mock).to receive(:suggest_streamer_goal).and_return(
          {
            goal_title: 'テスト目標',
            goal_description: 'テスト説明',
            action_plan: 'テスト計画'
          }
        )

        visit new_survey_profile_path
        expect(page).to have_content('もやもや結晶☁分析シート')

        # フォーム入力
        select 'YouTube', from: '配信プラットフォーム'
        select 'ゲーム実況', from: '配信ジャンル'
        select '初心者(1ヶ月未満)', from: '配信経験'
        fill_in 'survey_profile_weekly_frequency', with: 3
        fill_in 'survey_profile_average_listeners', with: 10
        fill_in 'survey_profile_total_listeners', with: 100
        select '1〜2人', from: '最近のリスナーの離脱人数'
        choose 'survey_profile_motivation_level_3'
        fill_in 'survey_profile_happy_moment', with: 'リスナーさんからコメントをもらえたとき'
        fill_in 'survey_profile_sad_moment', with: 'リスナーが全然増えない'
        check '稼ぎたい'
        check '有名になりたい'
        check '友達を作りたい'
        fill_in 'survey_profile_streaming_reasons_other', with: '特になし'
        fill_in 'survey_profile_desired_streaming_style', with: 'みんなでワイワイ楽しめる配信'
        fill_in 'survey_profile_desired_listener', with: '優しくて楽しい人'
        fill_in 'survey_profile_desired_monthly_income', with: 50_000

        choose 'goal_source_ai'

        # ⭐ perform_enqueued_jobs でジョブを同期実行
        perform_enqueued_jobs do
          click_button 'fetch-ai-button'
        end

        # ⭐ AI提案が表示されるまで待機（最大30秒）
        expect(page).to have_field('survey_result[goal_title]', with: 'テスト目標', wait: 30)
        expect(page).to have_field('survey_result[goal_description]', with: 'テスト説明', wait: 30)
        expect(page).to have_field('survey_result[action_plan]', with: /テスト計画/, wait: 30)
      end

      it 'AI提案を採用して目標作成できること', js: true do
        # どのインスタンスに対してもスタブが効くようにする
        allow_any_instance_of(GeminiService).to receive(:suggest_streamer_goal).and_return(
          {
            goal_title: 'テスト目標',
            goal_description: 'テスト説明',
            action_plan: 'テスト計画'
          }
        )

        # アンケートページに遷移
        visit new_survey_profile_path

        # ページが表示されるまで待機
        expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

        # フォーム入力
        select 'YouTube', from: '配信プラットフォーム'
        select 'ゲーム実況', from: '配信ジャンル'
        select '初心者(1ヶ月未満)', from: '配信経験'
        fill_in 'survey_profile_weekly_frequency', with: 3
        fill_in 'survey_profile_average_listeners', with: 10
        fill_in 'survey_profile_total_listeners', with: 100
        select '1〜2人', from: '最近のリスナーの離脱人数'
        choose 'survey_profile_motivation_level_3'
        fill_in 'survey_profile_happy_moment', with: 'リスナーさんからコメントをもらえたとき'
        fill_in 'survey_profile_sad_moment', with: 'リスナーが全然増えない'
        check '稼ぎたい'
        check '有名になりたい'
        check '友達を作りたい'
        fill_in 'survey_profile_streaming_reasons_other', with: '特になし'
        fill_in 'survey_profile_desired_streaming_style', with: 'みんなでワイワイ楽しめる配信'
        fill_in 'survey_profile_desired_listener', with: '優しくて楽しい人'
        fill_in 'survey_profile_desired_monthly_income', with: 50_000

        # AI提案から選択するラジオボタンを選択
        choose 'goal_source_ai'

        # ⭐ perform_enqueued_jobs でジョブを同期実行
        perform_enqueued_jobs do
          click_button 'fetch-ai-button'
        end

        # ⭐ AI提案が表示されるまで待機（最大30秒）
        expect(page).to have_field('survey_result[goal_title]', with: 'テスト目標', wait: 30), 'AI提案の目標タイトルが表示されません'

        # 成長の星を誕生させるボタンをクリック
        click_button '成長の星を誕生させる'

        # 目標作成ページに遷移することを確認
        expect(page).to have_current_path(%r{/goals/\d+}), '目標詳細ページに遷移しません'
        expect(page).to have_content('テスト目標'), '目標タイトルが表示されません'
        expect(page).to have_content('テスト説明'), '目標説明が表示されません'
        expect(page).to have_content('テスト計画'), 'アクションプランが表示されません'
      end
    end

    context '異常系' do
      context 'APIエラーが発生した場合' do
        before do
          # API エラーをモック
          allow_any_instance_of(GeminiService)
            .to receive(:suggest_streamer_goal)
            .and_raise(GeminiService::ApiError.new('API エラー'))
        end

        it 'エラーメッセージが表示されること', js: true do
          # アンケートページに遷移
          visit new_survey_profile_path

          # ページが表示されるまで待機
          expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

          # フォーム入力
          select 'YouTube', from: '配信プラットフォーム'
          select 'ゲーム実況', from: '配信ジャンル'
          select '初心者(1ヶ月未満)', from: '配信経験'
          fill_in 'survey_profile_weekly_frequency', with: 3
          fill_in 'survey_profile_average_listeners', with: 10
          fill_in 'survey_profile_total_listeners', with: 100
          select '1〜2人', from: '最近のリスナーの離脱人数'
          choose 'survey_profile_motivation_level_3'
          fill_in 'survey_profile_happy_moment', with: 'リスナーさんからコメントをもらえたとき'
          fill_in 'survey_profile_sad_moment', with: 'リスナーが全然増えない'
          check '稼ぎたい'
          check '有名になりたい'
          check '友達を作りたい'
          fill_in 'survey_profile_streaming_reasons_other', with: '特になし'
          fill_in 'survey_profile_desired_streaming_style', with: 'みんなでワイワイ楽しめる配信'
          fill_in 'survey_profile_desired_listener', with: '優しくて楽しい人'
          fill_in 'survey_profile_desired_monthly_income', with: 50_000

          allow_any_instance_of(GeminiService).to receive(:suggest_streamer_goal)
            .and_raise(GeminiService::ApiError.new('API エラー'))

          perform_enqueued_jobs do
            choose 'goal_source_ai'
            click_button 'fetch-ai-button'
          end

          expect(page).to have_content('AI提案の取得に失敗しました。もう一度お試しください。', wait: 10),
                          'エラーメッセージが表示されません'
        end
      end

      context 'パラメータが不正な場合' do
        it '必須項目が未入力の場合、エラーメッセージが表示されること', js: true do
          # アンケートページに遷移
          visit new_survey_profile_path

          # ページが表示されるまで待機
          expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

          # 自分で設定するラジオボタンを選択
          choose 'survey_result_goal_source_1'

          # 必須項目を入力せずに成長の星を誕生させるボタンをクリック
          click_button '成長の星を誕生させる'

          # バリデーションエラーメッセージが表示されることを確認
          expect(page).to have_content('配信プラットフォームを入力してください'), 'エラーメッセージが表示されません'
        end
      end
      context 'バリデーションエラーが発生した場合' do
        it '配信プラットフォームが未選択の場合、エラーメッセージが表示されること', js: true do
          # どのインスタンスに対してもスタブが効くようにする
          allow_any_instance_of(GeminiService).to receive(:suggest_streamer_goal).and_return(
            {
              goal_title: 'テスト目標',
              goal_description: 'テスト説明',
              action_plan: 'テスト計画'
            }
          )

          # アンケートページに遷移
          visit new_survey_profile_path

          # ページが表示されるまで待機
          expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

          # 配信プラットフォーム以外を入力
          select 'ゲーム実況', from: '配信ジャンル'
          select '初心者(1ヶ月未満)', from: '配信経験'
          fill_in 'survey_profile_weekly_frequency', with: 3
          fill_in 'survey_profile_average_listeners', with: 10
          fill_in 'survey_profile_total_listeners', with: 100
          select '1〜2人', from: '最近のリスナーの離脱人数'
          choose 'survey_profile_motivation_level_3'
          fill_in 'survey_profile_happy_moment', with: 'リスナーさんからコメントをもらえたとき'
          fill_in 'survey_profile_sad_moment', with: 'リスナーが全然増えない'
          check '稼ぎたい'
          fill_in 'survey_profile_streaming_reasons_other', with: '特になし'
          fill_in 'survey_profile_desired_streaming_style', with: 'みんなでワイワイ楽しめる配信'
          fill_in 'survey_profile_desired_listener', with: '優しくて楽しい人'
          fill_in 'survey_profile_desired_monthly_income', with: 50_000

          # AI提案から選択するラジオボタンを選択
          choose 'goal_source_ai'

          # ✨ AI提案を取得ボタンをクリック
          click_button 'fetch-ai-button'

          # JavaScript が実行されるまで待機
          sleep 3

          # AI提案が表示されるまで待機
          goal_title_field = page.find('input[name="survey_result[goal_title]"]', visible: :all)
          expect(goal_title_field.value).to eq('テスト目標'), 'AI提案の目標タイトルが表示されません'

          # 成長の星を誕生させるボタンをクリック
          click_button '成長の星を誕生させる'

          # バリデーションエラーメッセージが表示されることを確認
          expect(page).to have_selector('.alert'), 'エラーメッセージが表示されません'
          expect(page).to have_content('配信プラットフォームを入力してください'), 'バリデーションエラーが表示されません'
        end

        it '週の配信頻度が未入力の場合、エラーメッセージが表示されること', js: true do
          # どのインスタンスに対してもスタブが効くようにする
          allow_any_instance_of(GeminiService).to receive(:suggest_streamer_goal).and_return(
            {
              goal_title: 'テスト目標',
              goal_description: 'テスト説明',
              action_plan: 'テスト計画'
            }
          )

          # アンケートページに遷移
          visit new_survey_profile_path

          # ページが表示されるまで待機
          expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

          # 週の配信頻度以外を入力
          select 'YouTube', from: '配信プラットフォーム'
          select 'ゲーム実況', from: '配信ジャンル'
          select '初心者(1ヶ月未満)', from: '配信経験'
          fill_in 'survey_profile_average_listeners', with: 10
          fill_in 'survey_profile_total_listeners', with: 100
          select '1〜2人', from: '最近のリスナーの離脱人数'
          choose 'survey_profile_motivation_level_3'
          fill_in 'survey_profile_happy_moment', with: 'リスナーさんからコメントをもらえたとき'
          fill_in 'survey_profile_sad_moment', with: 'リスナーが全然増えない'
          check '稼ぎたい'
          fill_in 'survey_profile_streaming_reasons_other', with: '特になし'
          fill_in 'survey_profile_desired_streaming_style', with: 'みんなでワイワイ楽しめる配信'
          fill_in 'survey_profile_desired_listener', with: '優しくて楽しい人'
          fill_in 'survey_profile_desired_monthly_income', with: 50_000

          # AI提案から選択するラジオボタンを選択
          choose 'goal_source_ai'

          # ✨ AI提案を取得ボタンをクリック
          click_button 'fetch-ai-button'

          # JavaScript が実行されるまで待機
          sleep 3

          # AI提案が表示されるまで待機
          goal_title_field = page.find('input[name="survey_result[goal_title]"]', visible: :all)
          expect(goal_title_field.value).to eq('テスト目標'), 'AI提案の目標タイトルが表示されません'

          # 成長の星を誕生させるボタンをクリック
          click_button '成長の星を誕生させる'

          # バリデーションエラーメッセージが表示されることを確認
          expect(page).to have_selector('.alert'), 'エラーメッセージが表示されません'
          expect(page).to have_content('週あたりの配信回数を入力してください'), 'バリデーションエラーが表示されません'
        end
      end

      context '3回制限に達した場合' do
        before do
          # ユーザーのカウントを3に設定
          user.update!(ai_suggestion_count: 3, ai_suggestion_reset_date: Date.current)

          # どのインスタンスに対してもスタブが効くようにする
          allow_any_instance_of(GeminiService).to receive(:suggest_streamer_goal).and_return(
            {
              goal_title: 'テスト目標',
              goal_description: 'テスト説明',
              action_plan: 'テスト計画'
            }
          )
        end

        it '3回制限に達した後、エラーメッセージが表示されること', js: true do
          # アンケートページに遷移
          visit new_survey_profile_path

          # ページが表示されるまで待機
          expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

          # フォーム入力
          select 'YouTube', from: '配信プラットフォーム'
          select 'ゲーム実況', from: '配信ジャンル'
          select '初心者(1ヶ月未満)', from: '配信経験'
          fill_in 'survey_profile_weekly_frequency', with: 3
          fill_in 'survey_profile_average_listeners', with: 10
          fill_in 'survey_profile_total_listeners', with: 100
          select '1〜2人', from: '最近のリスナーの離脱人数'
          choose 'survey_profile_motivation_level_3'
          fill_in 'survey_profile_happy_moment', with: 'リスナーさんからコメントをもらえたとき'
          fill_in 'survey_profile_sad_moment', with: 'リスナーが全然増えない'
          check '稼ぎたい'
          check '有名になりたい'
          check '友達を作りたい'
          fill_in 'survey_profile_streaming_reasons_other', with: '特になし'
          fill_in 'survey_profile_desired_streaming_style', with: 'みんなでワイワイ楽しめる配信'
          fill_in 'survey_profile_desired_listener', with: '優しくて楽しい人'
          fill_in 'survey_profile_desired_monthly_income', with: 50_000

          # alert() が表示されることを確認
          alert_message = accept_alert do
            # AI提案から選択するラジオボタンを選択
            choose 'goal_source_ai'

            # ✨ AI提案を取得ボタンをクリック
            click_button 'fetch-ai-button'

            # アラートが表示されるまで待機
            sleep 3
          end

          # アラートのメッセージを検証
          expect(alert_message).to eq('AI提案の利用回数が上限（3回）に達しました。自分で設定する方法で目標を作成してください。'), 'エラーメッセージが表示されません'
        end
      end
    end
  end

  describe 'エッジケーステスト' do
    context '空の入力テスト' do
      it '必須項目を空で送信した場合、エラーメッセージが表示されること', js: true do
        # アンケートページに遷移
        visit new_survey_profile_path

        # ページが表示されるまで待機
        expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

        # 自分で設定するラジオボタンを選択
        choose 'survey_result_goal_source_1'

        # 必須項目を入力せずに成長の星を誕生させるボタンをクリック
        click_button '成長の星を誕生させる'

        # バリデーションエラーメッセージが表示されることを確認
        expect(page).to have_content('配信プラットフォームを入力してください'), 'エラーメッセージが表示されません'
        expect(page).to have_content('配信カテゴリーを入力してください'), 'エラーメッセージが表示されません'
        expect(page).to have_content('配信経験を入力してください'), 'エラーメッセージが表示されません'
        expect(page).to have_content('週あたりの配信回数を入力してください'), 'エラーメッセージが表示されません'
        expect(page).to have_content('平均視聴者数を入力してください'), 'エラーメッセージが表示されません'
      end
    end

    context '長文入力テスト' do
      it '自由記述欄に長文を入力した場合、正常に保存されること', js: true do
        # アンケートページに遷移
        visit new_survey_profile_path

        # ページが表示されるまで待機
        expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

        # フォーム入力（長文テスト）
        long_text = 'あ' * 1000 # 1000文字の長文

        select 'YouTube', from: '配信プラットフォーム'
        select 'ゲーム実況', from: '配信ジャンル'
        select '初心者(1ヶ月未満)', from: '配信経験'
        fill_in 'survey_profile_weekly_frequency', with: 3
        fill_in 'survey_profile_average_listeners', with: 10
        fill_in 'survey_profile_total_listeners', with: 100
        select '1〜2人', from: '最近のリスナーの離脱人数'
        choose 'survey_profile_motivation_level_3'

        # 長文を入力
        fill_in 'survey_profile_happy_moment', with: long_text
        fill_in 'survey_profile_sad_moment', with: long_text
        fill_in 'survey_profile_streaming_reasons_other', with: long_text
        fill_in 'survey_profile_desired_streaming_style', with: long_text
        fill_in 'survey_profile_desired_listener', with: long_text

        check '稼ぎたい'
        fill_in 'survey_profile_desired_monthly_income', with: 50_000

        # 自分で設定するラジオボタンを選択
        choose 'survey_result_goal_source_1'

        # 目標タイトルと説明を入力
        fill_in 'survey_result_goal_title', with: 'テスト目標'
        fill_in 'survey_result_goal_description', with: 'テスト説明'

        # 成長の星を誕生させるボタンをクリック
        click_button '成長の星を誕生させる'

        # 目標作成ページに遷移することを確認
        expect(page).to have_current_path(%r{/goals/\d+}), '目標詳細ページに遷移しません'
        expect(page).to have_content('テスト目標'), '目標タイトルが表示されません'
      end
    end

    context '特殊文字入力テスト' do
      it '特殊文字を入力した場合、正常に保存されること', js: true do
        # アンケートページに遷移
        visit new_survey_profile_path

        # ページが表示されるまで待機
        expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

        # フォーム入力（特殊文字テスト）
        special_chars = '!@#$%^&*()_+-=[]{}|;:\'",.<>?/~`'

        select 'YouTube', from: '配信プラットフォーム'
        select 'ゲーム実況', from: '配信ジャンル'
        select '初心者(1ヶ月未満)', from: '配信経験'
        fill_in 'survey_profile_weekly_frequency', with: 3
        fill_in 'survey_profile_average_listeners', with: 10
        fill_in 'survey_profile_total_listeners', with: 100
        select '1〜2人', from: '最近のリスナーの離脱人数'
        choose 'survey_profile_motivation_level_3'

        # 特殊文字を入力
        fill_in 'survey_profile_happy_moment', with: special_chars
        fill_in 'survey_profile_sad_moment', with: special_chars
        fill_in 'survey_profile_streaming_reasons_other', with: special_chars
        fill_in 'survey_profile_desired_streaming_style', with: special_chars
        fill_in 'survey_profile_desired_listener', with: special_chars

        check '稼ぎたい'
        fill_in 'survey_profile_desired_monthly_income', with: 50_000

        # 自分で設定するラジオボタンを選択
        choose 'survey_result_goal_source_1'

        # 目標タイトルと説明を入力
        fill_in 'survey_result_goal_title', with: 'テスト目標'
        fill_in 'survey_result_goal_description', with: 'テスト説明'

        # 成長の星を誕生させるボタンをクリック
        click_button '成長の星を誕生させる'

        # 目標作成ページに遷移することを確認
        expect(page).to have_current_path(%r{/goals/\d+}), '目標詳細ページに遷移しません'
        expect(page).to have_content('テスト目標'), '目標タイトルが表示されません'
      end
    end

    context '絵文字入力テスト' do
      it '絵文字を入力した場合、正常に保存されること', js: true do
        # アンケートページに遷移
        visit new_survey_profile_path

        # ページが表示されるまで待機
        expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

        # フォーム入力（絵文字テスト）
        emoji_text = '😀😃😄😁😆😅😂🤣😊😇'

        select 'YouTube', from: '配信プラットフォーム'
        select 'ゲーム実況', from: '配信ジャンル'
        select '初心者(1ヶ月未満)', from: '配信経験'
        fill_in 'survey_profile_weekly_frequency', with: 3
        fill_in 'survey_profile_average_listeners', with: 10
        fill_in 'survey_profile_total_listeners', with: 100
        select '1〜2人', from: '最近のリスナーの離脱人数'
        choose 'survey_profile_motivation_level_3'

        # 絵文字を入力
        page.execute_script("document.getElementById('survey_profile_happy_moment').value = '#{emoji_text}'")
        page.execute_script("document.getElementById('survey_profile_sad_moment').value = '#{emoji_text}'")
        page.execute_script("document.getElementById('survey_profile_streaming_reasons_other').value = '#{emoji_text}'")
        page.execute_script("document.getElementById('survey_profile_desired_streaming_style').value = '#{emoji_text}'")
        page.execute_script("document.getElementById('survey_profile_desired_listener').value = '#{emoji_text}'")

        check '稼ぎたい'
        fill_in 'survey_profile_desired_monthly_income', with: 50_000

        # 自分で設定するラジオボタンを選択
        choose 'survey_result_goal_source_1'

        # 目標タイトルと説明を入力
        fill_in 'survey_result_goal_title', with: 'テスト目標'
        fill_in 'survey_result_goal_description', with: 'テスト説明'

        # 成長の星を誕生させるボタンをクリック
        click_button '成長の星を誕生させる'

        # 目標作成ページに遷移することを確認
        expect(page).to have_current_path(%r{/goals/\d+}), '目標詳細ページに遷移しません'
        expect(page).to have_content('テスト目標'), '目標タイトルが表示されません'
      end
    end

    context 'HTMLタグ入力テスト' do
      it 'HTMLタグを入力した場合、エスケープされて保存されること', js: true do
        # アンケートページに遷移
        visit new_survey_profile_path

        # ページが表示されるまで待機
        expect(page).to have_content('もやもや結晶☁分析シート'), 'アンケートページが表示されません'

        # フォーム入力（HTMLタグテスト）
        html_tags = '<script>alert("XSS")</script><h1>見出し</h1><p>段落</p>'

        select 'YouTube', from: '配信プラットフォーム'
        select 'ゲーム実況', from: '配信ジャンル'
        select '初心者(1ヶ月未満)', from: '配信経験'
        fill_in 'survey_profile_weekly_frequency', with: 3
        fill_in 'survey_profile_average_listeners', with: 10
        fill_in 'survey_profile_total_listeners', with: 100
        select '1〜2人', from: '最近のリスナーの離脱人数'
        choose 'survey_profile_motivation_level_3'

        # HTMLタグを入力
        fill_in 'survey_profile_happy_moment', with: html_tags
        fill_in 'survey_profile_sad_moment', with: html_tags
        fill_in 'survey_profile_streaming_reasons_other', with: html_tags
        fill_in 'survey_profile_desired_streaming_style', with: html_tags
        fill_in 'survey_profile_desired_listener', with: html_tags

        check '稼ぎたい'
        fill_in 'survey_profile_desired_monthly_income', with: 50_000

        # 自分で設定するラジオボタンを選択
        choose 'survey_result_goal_source_1'

        # 目標タイトルと説明を入力
        fill_in 'survey_result_goal_title', with: 'テスト目標'
        fill_in 'survey_result_goal_description', with: 'テスト説明'

        # 成長の星を誕生させるボタンをクリック
        click_button '成長の星を誕生させる'

        # 目標作成ページに遷移することを確認
        expect(page).to have_current_path(%r{/goals/\d+}), '目標詳細ページに遷移しません'
        expect(page).to have_content('テスト目標'), '目標タイトルが表示されません'
      end
    end
  end
end
