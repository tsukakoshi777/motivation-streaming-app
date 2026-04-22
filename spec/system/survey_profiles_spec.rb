# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SurveyProfiles', type: :system do
  let(:user) { create(:user) }
  let!(:streaming_platform) { create(:streaming_platform, name: 'YouTube') }
  let!(:streaming_category) { create(:streaming_category, name: 'ゲーム実況') }
  let!(:streaming_experience) { create(:streaming_experience, name: '初心者(1ヶ月未満)') }

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

        # GeminiService.new が呼ばれたときに、モックを返す
        allow(GeminiService).to receive(:new).and_return(gemini_service_mock)

        # モックの suggest_streamer_goal メソッドをスタブ化
        allow(gemini_service_mock).to receive(:suggest_streamer_goal).and_return(
          {
            goal_title: 'テスト目標',
            goal_description: 'テスト説明',
            action_plan: 'テスト計画'
          }
        )

        # アンケートページに遷移
        visit new_survey_profile_path

        # デバッグ1: JavaScriptファイルが読み込まれているか確認
        puts "\n=== JavaScriptファイルの確認 ==="
        js_files = page.all('script[src]', visible: false)
        puts "読み込まれているJSファイル数: #{js_files.count}"
        js_files.each { |script| puts "  - #{script[:src]}" }

        # ページが表示されるまで待機
        expect(page).to have_content('もやもや結晶シート'), 'アンケートページが表示されません'

        # フォーム入力
        select 'YouTube', from: '配信プラットフォーム'
        select 'ゲーム実況', from: '配信ジャンル'
        select '初心者(1ヶ月未満)', from: '配信経験'
        fill_in 'survey_profile_weekly_frequency', with: 3
        fill_in 'survey_profile_average_listeners', with: 10
        fill_in 'survey_profile_total_listeners', with: 100
        select '1〜2人', from: '最近のリスナーの離脱人数'

        # モチベーションレベルはラジオボタンなので choose を使う
        choose 'survey_profile_motivation_level_3'

        fill_in 'survey_profile_happy_moment', with: 'リスナーさんからコメントをもらえたとき'
        fill_in 'survey_profile_sad_moment', with: 'リスナーが全然増えない'

        # チェックボックスは check を使う
        check '稼ぎたい'
        check '有名になりたい'
        check '友達を作りたい'

        fill_in 'survey_profile_streaming_reasons_other', with: '特になし'
        fill_in 'survey_profile_desired_streaming_style', with: 'みんなでワイワイ楽しめる配信'
        fill_in 'survey_profile_desired_listener', with: '優しくて楽しい人'
        fill_in 'survey_profile_desired_monthly_income', with: 50_000

        # デバッグ2: ラジオボタン選択前の状態
        puts "\n=== ラジオボタン選択前 ==="
        puts "goal_source_ai の存在: #{page.has_selector?('#goal_source_ai', visible: :all)}"

        # AI提案から選択するラジオボタンを選択
        choose 'goal_source_ai'

        # JavaScript が実行されるまで待機
        sleep 3

        begin
          alert = page.driver.browser.switch_to.alert
          puts "\n=== アラート内容 ==="
          puts "アラートテキスト: #{alert.text}"
          alert.accept # アラートを閉じる
        rescue Selenium::WebDriver::Error::NoSuchAlertError
          puts 'アラートは表示されませんでした'
        end

        # アラートを閉じた後にラジオボタンの状態を確認
        puts "\n=== ラジオボタンの状態 ==="
        puts "ラジオボタンがチェック済み: #{page.has_checked_field?('goal_source_ai')}"

        # デバッグ4: ブラウザのコンソールログ確認
        puts "\n=== ブラウザコンソールログ ==="
        begin
          logs = page.driver.browser.logs.get(:browser)
          if logs.any?
            logs.each { |log| puts "  [#{log.level}] #{log.message}" }
          else
            puts '  (ログなし)'
          end
        rescue StandardError => e
          puts "  ログ取得不可: #{e.message}"
        end

        # AI提案が表示されるまで待機
        goal_title_field = page.find('input[name="survey_result[goal_title]"]', visible: :all)
        expect(goal_title_field.value).to eq('テスト目標'), 'AI提案の目標タイトルが表示されません'

        goal_description_field = page.find('textarea[name="survey_result[goal_description]"]', visible: :all)
        expect(goal_description_field.value).to eq('テスト説明'), 'AI提案の目標説明が表示されません'

        action_plan_field = page.find('textarea[name="survey_result[action_plan]"]', visible: :all)
        expect(action_plan_field.value).to include('テスト計画'), 'AI提案のアクションプランが表示されません'
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
        expect(page).to have_content('もやもや結晶シート'), 'アンケートページが表示されません'

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

        # JavaScript が実行されるまで待機
        sleep 3

        # AI提案が表示されるまで待機
        goal_title_field = page.find('input[name="survey_result[goal_title]"]', visible: :all)
        expect(goal_title_field.value).to eq('テスト目標'), 'AI提案の目標タイトルが表示されません'

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
          expect(page).to have_content('もやもや結晶シート'), 'アンケートページが表示されません'

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

            # アラートが表示されるまで待機
            sleep 3
          end

          # アラートのメッセージを検証
          expect(alert_message).to eq('AI提案の取得に失敗しました。もう一度お試しください。'), 'エラーメッセージが表示されません'
        end
      end

      context 'パラメータが不正な場合' do
        it '必須項目が未入力の場合、エラーメッセージが表示されること', js: true do
          # アンケートページに遷移
          visit new_survey_profile_path

          # ページが表示されるまで待機
          expect(page).to have_content('もやもや結晶シート'), 'アンケートページが表示されません'

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
          expect(page).to have_content('もやもや結晶シート'), 'アンケートページが表示されません'

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
          expect(page).to have_content('もやもや結晶シート'), 'アンケートページが表示されません'

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
    end
  end
end
