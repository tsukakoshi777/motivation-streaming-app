# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard', type: :system do
  let(:user) { create(:user) }

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

  # Phase 2: ダッシュボード統計のテスト
  describe 'ダッシュボード統計' do
    context '統計表示' do
      # 各 Goal に別々の survey_profile を作成
      let!(:survey_profile1) { create(:survey_profile, user: user) }
      let!(:survey_profile2) { create(:survey_profile, user: user) }
      let!(:survey_profile3) { create(:survey_profile, user: user) }

      before do
        survey_profile1.survey_result.update!(goal_title: 'テスト目標1', goal_description: 'テスト説明1')
        survey_profile2.survey_result.update!(goal_title: 'テスト目標2', goal_description: 'テスト説明2')
        survey_profile3.survey_result.update!(goal_title: 'テスト目標3', goal_description: 'テスト説明3')
      end

      let!(:goal1) { create(:goal, user: user, survey_profile: survey_profile1) }
      let!(:goal2) { create(:goal, user: user, survey_profile: survey_profile2) }
      let!(:goal3) { create(:goal, user: user, survey_profile: survey_profile3) }

      before do
        # goal1に輝きメモを5件作成（星0個）
        create_list(:spark, 5, goal: goal1, user: user)

        # goal2に輝きメモを25件作成（星1個）
        create_list(:spark, 25, goal: goal2, user: user)

        # goal3に輝きメモを10件作成（星0個）
        create_list(:spark, 10, goal: goal3, user: user)
      end

      it '見つかった成長の星の数が正しく表示される' do
        # ダッシュボードにアクセス
        visit dashboard_path

        # 見つかった成長の星: 3個（goal1, goal2, goal3）
        expect(page).to have_content('見つかった成長の星')
        expect(page).to have_content('3個')
      end

      it '達成した成長の星の数が正しく表示される' do
        # ダッシュボードにアクセス
        visit dashboard_path

        # 達成した成長の星: 1個（goal2のみ20件以上）
        expect(page).to have_content('達成した成長の星')
        expect(page).to have_content('1個')
      end

      it '総輝きメモ件数が正しく表示される' do
        # ダッシュボードにアクセス
        visit dashboard_path

        # 総輝きメモ: 40件（5 + 25 + 10）
        expect(page).to have_content('宿した輝きの数')
        expect(page).to have_content('40件')
      end
    end
  end

  # Phase 2: きらめきバッジのテスト
  describe 'きらめきバッジ' do
    context '輝きメモが10件以上の場合' do
      let!(:survey_profile) { create(:survey_profile, user: user) }
      let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

      before do
        survey_profile.survey_result.update!(goal_title: 'テスト目標', goal_description: 'テスト説明')
        create_list(:spark, 10, goal: goal, user: user)
      end

      it '「継続の証」バッジが表示される' do
        visit dashboard_path

        expect(page).to have_content('継続の証')
        expect(page).to have_content('🌠')
      end
    end

    context '達成した成長の星が1個以上の場合' do
      let!(:survey_profile) { create(:survey_profile, user: user) }
      let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

      before do
        survey_profile.survey_result.update!(goal_title: 'テスト目標', goal_description: 'テスト説明')
        create_list(:spark, 20, goal: goal, user: user)
      end

      it '「目標達成者」バッジが表示される' do
        visit dashboard_path

        expect(page).to have_content('目標達成者')
        expect(page).to have_content('🌟')
      end
    end

    context '輝きメモが30件以上の場合' do
      let!(:survey_profile) { create(:survey_profile, user: user) }
      let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

      before do
        survey_profile.survey_result.update!(goal_title: 'テスト目標', goal_description: 'テスト説明')
        create_list(:spark, 30, goal: goal, user: user)
      end

      it '「輝きの達人」バッジが表示される' do
        visit dashboard_path

        expect(page).to have_content('輝きの達人')
        expect(page).to have_content('💫')
      end
    end

    context '目標が3個以上の場合' do
      let!(:survey_profile1) { create(:survey_profile, user: user) }
      let!(:survey_profile2) { create(:survey_profile, user: user) }
      let!(:survey_profile3) { create(:survey_profile, user: user) }

      let!(:goal1) { create(:goal, user: user, survey_profile: survey_profile1) }
      let!(:goal2) { create(:goal, user: user, survey_profile: survey_profile2) }
      let!(:goal3) { create(:goal, user: user, survey_profile: survey_profile3) }

      before do
        survey_profile1.survey_result.update!(goal_title: 'テスト目標1', goal_description: 'テスト説明1')
        survey_profile2.survey_result.update!(goal_title: 'テスト目標2', goal_description: 'テスト説明2')
        survey_profile3.survey_result.update!(goal_title: 'テスト目標3', goal_description: 'テスト説明3')
      end

      it '「マルチタスカー」バッジが表示される' do
        visit dashboard_path

        expect(page).to have_content('マルチタスカー')
        expect(page).to have_content('⭐')
      end
    end
  end

  describe 'グラフ表示' do
    context '月別の輝きメモ件数グラフ' do
      let!(:survey_profile) { create(:survey_profile, user: user) }

      before do
        survey_profile.survey_result.update!(goal_title: 'テスト目標', goal_description: 'テスト説明')
      end

      let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

      before do
        # 現在の日付から過去3ヶ月分のデータを作成
        create_list(:spark, 3, goal: goal, user: user, created_at: 1.month.ago)
        create_list(:spark, 5, goal: goal, user: user, created_at: 2.months.ago)
        create_list(:spark, 2, goal: goal, user: user, created_at: 3.months.ago)
      end

      it 'ダッシュボードページに月別の輝きメモ件数グラフが表示される', js: true do
        # ダッシュボードにアクセス
        visit dashboard_path

        # ページの読み込みが完了するまで待つ
        expect(page).to have_css('[data-controller="chart"]', wait: 10)

        # 棒グラフ（bar）の canvas 要素を取得
        using_wait_time(10) do
          expect(page).to have_selector('canvas[data-chart-type-value="bar"]'), '月別の輝きメモ件数グラフが表示されていません'
        end

        # 棒グラフの data-chart-data-value 属性の中身を検証
        chart_element = page.find('canvas[data-chart-type-value="bar"]')
        chart_data = chart_element['data-chart-data-value']

        # 現在の日付から過去の月を計算
        one_month_ago = 1.month.ago.strftime('%Y年%m月')
        two_months_ago = 2.months.ago.strftime('%Y年%m月')
        three_months_ago = 3.months.ago.strftime('%Y年%m月')

        expect(chart_data).to include(one_month_ago), "#{one_month_ago}のデータが表示されていません"
        expect(chart_data).to include(two_months_ago), "#{two_months_ago}のデータが表示されていません"
        expect(chart_data).to include(three_months_ago), "#{three_months_ago}のデータが表示されていません"
      end
    end

    context '目標別の輝きメモ件数グラフ(円グラフ)' do
      let!(:survey_profile1) { create(:survey_profile, user: user) }
      let!(:survey_profile2) { create(:survey_profile, user: user) }
      let!(:survey_profile3) { create(:survey_profile, user: user) }

      before do
        survey_profile1.survey_result.update!(goal_title: 'テスト目標1', goal_description: 'テスト説明1')
        survey_profile2.survey_result.update!(goal_title: 'テスト目標2', goal_description: 'テスト説明2')
        survey_profile3.survey_result.update!(goal_title: 'テスト目標3', goal_description: 'テスト説明3')
      end

      let!(:goal1) { create(:goal, user: user, survey_profile: survey_profile1) }
      let!(:goal2) { create(:goal, user: user, survey_profile: survey_profile2) }
      let!(:goal3) { create(:goal, user: user, survey_profile: survey_profile3) }

      before do
        # goal1に輝きメモを5件作成
        create_list(:spark, 5, goal: goal1, user: user)

        # goal2に輝きメモを10件作成
        create_list(:spark, 10, goal: goal2, user: user)

        # goal3に輝きメモを3件作成
        create_list(:spark, 3, goal: goal3, user: user)
      end

      it 'ダッシュボードページに目標別の輝きメモ件数グラフ(円グラフ)が表示される', js: true do
        # ダッシュボードにアクセス
        visit dashboard_path

        # ページの読み込みが完了するまで待つ
        expect(page).to have_css('[data-controller="chart"]', wait: 10)

        # 円グラフ(pie)の canvas 要素を取得
        using_wait_time(10) do
          expect(page).to have_selector('canvas[data-chart-type-value="pie"]'), '目標別の輝きメモ件数グラフ(円グラフ)が表示されていません'
        end

        # 円グラフの data-chart-data-value 属性の中身を検証
        chart_element = page.find('canvas[data-chart-type-value="pie"]')
        chart_data = chart_element['data-chart-data-value']

        # 目標タイトルが含まれていることを確認
        expect(chart_data).to include('テスト目標1'), 'テスト目標1のデータが表示されていません'
        expect(chart_data).to include('テスト目標2'), 'テスト目標2のデータが表示されていません'
        expect(chart_data).to include('テスト目標3'), 'テスト目標3のデータが表示されていません'
      end

      it '円グラフに正しいデータが含まれている', js: true do
        # ダッシュボードにアクセス
        visit dashboard_path

        # ページの読み込みが完了するまで待つ
        expect(page).to have_css('[data-controller="chart"]', wait: 10)

        # 円グラフの canvas 要素を取得
        using_wait_time(10) do
          expect(page).to have_selector('canvas[data-chart-type-value="pie"]')
        end

        # 円グラフの data-chart-data-value 属性の中身を検証
        chart_element = page.find('canvas[data-chart-type-value="pie"]')
        chart_data = JSON.parse(chart_element['data-chart-data-value'])

        # データセットの件数を確認
        expect(chart_data['datasets'].first['data'].sum).to eq(18), '輝きメモの総件数が正しくありません'

        # ラベルの数を確認
        expect(chart_data['labels'].size).to eq(3), '目標の数が正しくありません'
      end

      context '輝きメモが存在しない場合' do
        before do
          # 前のテストで作成されたデータをすべて削除
          Spark.destroy_all
        end

        let!(:survey_profile) { create(:survey_profile, user: user) }
        let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

        before do
          survey_profile.survey_result.update!(goal_title: 'テスト目標', goal_description: 'テスト説明')
        end

        it '「データがありません」と表示される' do
          visit dashboard_path

          # グラフのタイトルが表示されることを確認
          expect(page).to have_content('各成長の星の輝き割合')

          # 「データがありません」メッセージが表示されることを確認
          expect(page).to have_content('データがありません')
        end
      end
    end
  end
end
