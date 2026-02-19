# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Goals', type: :system do
  let(:user) { create(:user) }

  before do
    # ⭐ ログイン処理
    visit login_path

    # ⭐ ログインページが表示されるまで待機
    expect(page).to have_content('ログイン'), 'ログインページが表示されません'

    # ⭐ フォームのフィールド名を確認
    fill_in 'email', with: user.email
    fill_in 'password', with: 'password'

    # ⭐ デバッグ: スクリーンショットを撮影
    # page.save_screenshot('tmp/capybara/before_click_login.png')

    click_button 'ログイン'

    # ⭐ デバッグ: スクリーンショットを撮影
    # page.save_screenshot('tmp/capybara/after_click_login.png')

    # ⭐ ログイン成功を確認
    expect(page).to have_content('ログインしました'), 'ログインに失敗しました'
  end

  describe '一覧機能' do
    context '目標が存在する場合' do
      let!(:survey_profile1) { create(:survey_profile, user: user) }
      let!(:survey_profile2) { create(:survey_profile, user: user) }

      # ⭐ goal を作成（これが必要!）
      let!(:goal1) { create(:goal, user: user, survey_profile: survey_profile1) }
      let!(:goal2) { create(:goal, user: user, survey_profile: survey_profile2) }

      before do
        # ⭐ デバッグ用: survey_result が存在するか確認
        puts '========== survey_profile1 =========='
        puts "ID: #{survey_profile1.id}"
        puts "survey_result: #{survey_profile1.survey_result.inspect}"
        puts "goal_title: #{survey_profile1.survey_result.goal_title}"
        puts '===================================='

        puts '========== survey_profile2 =========='
        puts "ID: #{survey_profile2.id}"
        puts "survey_result: #{survey_profile2.survey_result.inspect}"
        puts "goal_title: #{survey_profile2.survey_result.goal_title}"
        puts '===================================='

        # ⭐ goal_title を更新
        survey_profile1.survey_result.update!(goal_title: '目標1', goal_description: '説明1')
        survey_profile2.survey_result.update!(goal_title: '目標2', goal_description: '説明2')

        # ⭐ デバッグ用: 更新後の goal_title を確認
        puts '========== 更新後 =========='
        puts "survey_profile1.goal_title: #{survey_profile1.survey_result.goal_title}"
        puts "survey_profile2.goal_title: #{survey_profile2.survey_result.goal_title}"
        puts '============================'

        # ⭐ デバッグ用: goal が作成されているか確認
        puts '========== goal1 =========='
        puts "ID: #{goal1.id}"
        puts "survey_profile_id: #{goal1.survey_profile_id}"
        puts '===================================='

        puts '========== goal2 =========='
        puts "ID: #{goal2.id}"
        puts "survey_profile_id: #{goal2.survey_profile_id}"
        puts '===================================='

        # ⭐ ログイン処理（手動）
        visit login_path
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'password' # FactoryBot で設定したパスワード
        click_button 'ログイン'

        # ⭐ goals_path にアクセス
        visit goals_path
      end

      it '目標の一覧が表示される' do
        expect(page).to have_content('目標1')
        expect(page).to have_content('目標2')
      end
    end

    context '目標が0件の場合' do
      before do
        # ⭐ goals_path にアクセス
        visit goals_path
      end

      it 'メッセージが表示される' do
        expect(page).to have_content('まだ成長の星⭐が見つかっていません')
      end
    end
  end

  describe '編集機能' do
    # ⭐ survey_profile を作成すると、自動的に survey_result も作成される
    let!(:survey_profile) { create(:survey_profile, user: user) }

    # ⭐ goal を作成（これが重要!）
    let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

    before do
      # ⭐ survey_result の goal_title をカスタマイズ（必要な場合のみ）
      survey_profile.survey_result.update!(goal_title: '目標1', goal_description: '説明1')

      visit goals_path
    end

    it '編集画面が表示されること' do
      # ⭐ デバッグ用: 編集ボタンの存在を確認
      if page.has_css?('.btn-secondary', text: '編集')
        puts '✅ 編集ボタンが見つかりました'
      else
        puts '❌ 編集ボタンが見つかりませんでした'
      end

      # ⭐ 編集ボタンをクリック
      first('.btn-secondary', text: '編集').click

      expect(page).to have_content('成長の星を編集')
    end

    it '編集内容が保存されること' do
      # 🔍 デバッグ: goal が取得できているか確認
      puts '=== デバッグ情報 ==='
      puts "survey_profile: #{survey_profile.inspect}"
      puts "goal: #{goal.inspect}"
      puts "goal.id: #{goal&.id}"
      puts "goal.class: #{goal&.class}"
      puts '==================='

      # 🔍 デバッグ: パスの確認
      path = edit_goal_path(goal)
      puts "edit_goal_path(goal): #{path}"
      puts '==================='

      visit edit_goal_path(goal)

      # 🔍 デバッグ: ページのHTMLを保存
      # save_and_open_page

      # ⭐ 週の配信頻度を編集
      fill_in 'survey_profile_weekly_frequency', with: 5

      click_button '成長の星を更新'

      expect(page).to have_content('成長の星を更新しました')
    end

    it 'バリデーションエラーが表示されること' do
      visit edit_goal_path(goal)

      fill_in '週の配信頻度', with: ''

      click_button '成長の星を更新'

      expect(page).to have_content('Weekly frequencyを入力してください')
    end
  end

  describe '削除機能', js: true do
    # ⭐ survey_profile を作成すると、自動的に survey_result も作成される
    let!(:survey_profile) { create(:survey_profile, user: user) }

    let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

    before do
      # ⭐ survey_result の goal_title をカスタマイズ（必要な場合のみ）
      survey_profile.survey_result.update!(goal_title: '目標1', goal_description: '説明1')

      # ⭐ goals_path にアクセス
      visit goals_path
    end

    it '削除確認ダイアログが表示され、削除されること' do
      expect(page).to have_content('目標1')

      # ⭐ accept_confirm で確認ダイアログを受け入れる
      accept_confirm do
        # ⭐ button_to で生成されたボタンをクリック
        first('.btn.text-danger', text: '削除').click
      end

      # ⭐ フラッシュメッセージを確認
      expect(page).to have_content('成長の星を削除しました')
    end

    it 'データが削除されること' do
      # ⭐ 削除前のカウントを取得
      initial_count = Goal.count

      # ⭐ accept_confirm で確認ダイアログを受け入れる
      accept_confirm do
        first('.btn.text-danger', text: '削除').click
      end

      # ⭐ フラッシュメッセージが表示されるまで待つ（削除処理の完了を確認）
      expect(page).to have_content('成長の星を削除しました')

      # ⭐ 「目標1」が画面から消えるまで待つ
      expect(page).not_to have_content('目標1')

      # ⭐ 削除後のカウントを確認
      expect(Goal.count).to eq(initial_count - 1)
    end

    it '削除後、一覧に表示されないこと' do
      # ⭐ accept_confirm で確認ダイアログを受け入れる
      accept_confirm do
        first('.btn.text-danger', text: '削除').click
      end

      # ⭐ 削除後、「目標1」が表示されないことを確認
      expect(page).not_to have_content('目標1')
    end
  end
end
