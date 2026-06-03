# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sparks', type: :system do
  let(:user) { create(:user) }

  # survey_profile を作成すると、自動的に survey_result も作成される
  let!(:survey_profile) { create(:survey_profile, user: user) }

  # goal を作成
  let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

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

  describe '輝きの投稿' do
    it '輝きを投稿できること' do
      visit goal_path(goal)

      # ページが表示されるまで待機
      expect(page).to have_css('textarea[name="spark[content]"]'), 'フォームが表示されません'

      fill_in 'spark[content]', with: '今日も頑張ろう！'
      click_button '輝きを記録'

      # 投稿内容が表示されるまで待機
      expect(page).to have_content('今日も頑張ろう！'), '投稿内容が表示されません'
      expect(page).to have_content('輝きを記録しました'), 'フラッシュメッセージが表示されません'
    end

    it '空の内容では投稿できないこと' do
      visit goal_path(goal)

      # ページが表示されるまで待機
      expect(page).to have_css('textarea[name="spark[content]"]'), 'フォームが表示されません'

      fill_in 'spark[content]', with: ''
      click_button '輝きを記録'

      # エラーメッセージが表示されるまで待機
      expect(page).to have_content('を入力してください'), 'エラーメッセージが表示されません'
    end

    it '500文字を超える内容では投稿できないこと' do
      visit goal_path(goal)

      # ページが表示されるまで待機
      expect(page).to have_css('textarea[name="spark[content]"]'), 'フォームが表示されません'

      fill_in 'spark[content]', with: 'a' * 501
      click_button '輝きを記録'

      # エラーメッセージが表示されるまで待機
      expect(page).to have_content('は500文字以内で入力してください'), 'エラーメッセージが表示されません'
    end
  end

  describe '輝きの編集' do
    let!(:spark) { create(:spark, goal: goal, user: user, content: '元の内容') }

    it '輝きを編集できること' do
      visit goal_path(goal)

      # 投稿内容が表示されるまで待機
      expect(page).to have_content('元の内容'), '投稿内容が表示されません'

      # data-turbo-stream 属性を持つ編集リンクをクリック
      find('a[data-turbo-stream="true"]', text: '編集').click

      # 編集フォームが表示されるまで待機
      expect(page).to have_css('textarea[name="spark[content]"]'), '編集フォームが表示されません'

      textarea = find("textarea#spark_edit_content_#{spark.id}")
      textarea.native.clear
      textarea.set('編集後の内容')

      click_button '更新する'

      # 編集後の内容が表示されるまで待機
      expect(page).to have_content('編集後の内容'), '編集後の内容が表示されません'
      expect(page).to have_content('輝きを更新しました'), 'フラッシュメッセージが表示されません'
      expect(page).not_to have_content('元の内容'), '元の内容が残っています'
    end

    it '編集をキャンセルできること' do
      visit goal_path(goal)

      # 投稿内容が表示されるまで待機
      expect(page).to have_content('元の内容'), '投稿内容が表示されません'

      # data-turbo-stream 属性を持つ編集リンクをクリック
      find('a[data-turbo-stream="true"]', text: '編集').click

      # 編集フォームが表示されるまで待機
      expect(page).to have_css('textarea[name="spark[content]"]'), '編集フォームが表示されません'

      # data-turbo-stream 属性を持つキャンセルリンクをクリック
      find('a[data-turbo-stream="true"]', text: 'キャンセル').click

      # 元の内容が表示され、フォームが非表示になるまで待機
      expect(page).to have_content('元の内容'), '元の内容が表示されません'
      expect(page).not_to have_css('form.spark-edit-form'), '編集フォームが残っています'
    end
  end

  describe '輝きの削除', js: true do
    let!(:spark) { create(:spark, goal: goal, user: user, content: '削除する内容') }

    it '輝きを削除できること' do
      visit goal_path(goal)

      # 投稿内容が表示されるまで待機
      expect(page).to have_content('削除する内容'), '投稿内容が表示されません'

      # data-turbo-confirm 属性を持つ削除ボタンを特定してクリック
      accept_confirm('本当に削除しますか?') do
        find('button[data-turbo-confirm="本当に削除しますか?"]', text: '削除').click
      end

      # フラッシュメッセージが表示されるまで待機
      expect(page).to have_content('輝きを削除しました'), 'フラッシュメッセージが表示されません'

      # 削除された内容が表示されないことを確認
      expect(page).not_to have_content('削除する内容'), '削除された内容が残っています'
    end

    it 'データが削除されること' do
      visit goal_path(goal)

      # 投稿内容が表示されるまで待機
      expect(page).to have_content('削除する内容'), '投稿内容が表示されません'

      # 削除前のカウントを取得
      initial_count = Spark.count

      # data-turbo-confirm 属性を持つ削除ボタンを特定してクリック
      accept_confirm('本当に削除しますか?') do
        find('button[data-turbo-confirm="本当に削除しますか?"]', text: '削除').click
      end

      # フラッシュメッセージが表示されるまで待機(削除処理の完了を確認)
      expect(page).to have_content('輝きを削除しました'), 'フラッシュメッセージが表示されません'

      # 「削除する内容」が画面から消えるまで待つ
      expect(page).not_to have_content('削除する内容'), '削除された内容が残っています'

      #  削除後のカウントを確認
      expect(Spark.count).to eq(initial_count - 1), 'データが削除されていません'
    end

    it '削除後、一覧に表示されないこと' do
      visit goal_path(goal)

      #  投稿内容が表示されるまで待機
      expect(page).to have_content('削除する内容'), '投稿内容が表示されません'

      #  data-turbo-confirm 属性を持つ削除ボタンを特定してクリック
      accept_confirm('本当に削除しますか?') do
        find('button[data-turbo-confirm="本当に削除しますか?"]', text: '削除').click
      end

      #  フラッシュメッセージが表示されるまで待機
      expect(page).to have_content('輝きを削除しました'), 'フラッシュメッセージが表示されません'

      #  削除後、「削除する内容」が表示されないことを確認
      expect(page).not_to have_content('削除する内容'), '削除された内容が残っています'
    end
  end

  # ========================================
  # 【追加】 輝きのページネーションのテスト
  # ========================================

  describe '輝き一覧のページネーション' do
    context 'ページネーションが機能する場合' do
      before do
        # 10件の輝きを作成（1ページ4件の場合、3ページ必要）
        10.times do |i|
          create(:spark, goal: goal, user: user, content: "輝き#{i + 1}")
        end

        visit goal_path(goal)
      end

      it '1ページ目に4件の輝きが表示される' do
        # 輝きのカードを数える
        expect(page).to have_css('.spark-item', count: 4)
      end

      it '2ページ目に移動できる' do
        # 1ページ目に表示される輝きを確認
        expect(page).to have_content('輝き10')
        expect(page).to have_content('輝き9')

        click_link '2'

        # 2ページ目に表示される輝きを確認（1ページ目の輝きが消えていることを確認）
        expect(page).not_to have_content('輝き10')
        expect(page).not_to have_content('輝き9')

        # 2ページ目の輝きが表示されることを確認
        expect(page).to have_content('輝き6')
        expect(page).to have_content('輝き5')
      end

      it '2ページ目に4件の輝きが表示される' do
        click_link '2'
        expect(page).to have_css('.spark-item', count: 4)
      end

      it '3ページ目に2件の輝きが表示される' do
        click_link '3'
        expect(page).to have_css('.spark-item', count: 2)
      end

      it 'ページネーションのリンクが正しく表示される' do
        expect(page).to have_css('.pagination')
        expect(page).to have_link('2')
        expect(page).to have_link('3')
      end

      it '輝きの内容が表示される' do
        # 降順表示の場合、最新の輝きが表示される
        expect(page).to have_content('輝き10')
        expect(page).to have_content('輝き9')
        expect(page).to have_content('輝き8')
        expect(page).to have_content('輝き7')
      end
    end

    context 'ページネーションが不要な場合' do
      before do
        # 3件の輝きを作成
        3.times do |i|
          create(:spark, goal: goal, user: user, content: "輝き#{i + 1}")
        end

        visit goal_path(goal)
      end

      it 'ページネーションが表示されない' do
        expect(page).not_to have_css('.pagination')
      end

      it '全ての輝きが表示される' do
        expect(page).to have_css('.spark-item', count: 3)
      end

      it '輝きの内容が表示される' do
        expect(page).to have_content('輝き3')
        expect(page).to have_content('輝き2')
        expect(page).to have_content('輝き1')
      end
    end

    context '輝きを投稿した後のページネーション', js: true do
      before do
        # 4件の輝きを作成（1ページ目がちょうど埋まる）
        4.times do |i|
          create(:spark, goal: goal, user: user, content: "既存の輝き#{i + 1}")
        end

        visit goal_path(goal)
      end

      it '新しい輝きを投稿すると1ページ目に表示される' do
        # 輝きを投稿
        fill_in 'spark[content]', with: '新しい輝き'
        click_button '輝きを記録'

        # 投稿が成功するまで待機
        expect(page).to have_content('輝きを記録しました'), 'フラッシュメッセージが表示されません'

        # 1ページ目に新しい輝きが表示される
        expect(page).to have_content('新しい輝き')

        # 1ページ目に4件の輝きが表示される（新しい輝きが1番上に表示される）
        expect(page).to have_css('.spark-item', count: 4)

        # 2ページ目に移動できる
        expect(page).to have_link('2')
      end
    end
  end
end
