# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Goals::Autocomplete', type: :system do
  let(:user) { create(:user) }

  before do
    # ログイン処理
    visit login_path

    # ログインページが表示されるまで待機
    expect(page).to have_content('ログイン'), 'ログインページが表示されません'

    # ログインフォームに入力
    fill_in 'メールアドレス', with: user.email
    fill_in 'パスワード', with: 'password'

    click_button 'ログイン'

    # ログイン成功を確認
    expect(page).to have_content('ログインしました'), 'ログインに失敗しました'

    # テストデータを作成
    survey_profile1 = create(:survey_profile, user: user)
    survey_profile1.survey_result.update!(
      goal_title: 'Ruby学習',
      goal_description: 'Railsの入門を学ぶ'
    )
    create(:goal, user: user, survey_profile: survey_profile1)

    survey_profile2 = create(:survey_profile, user: user)
    survey_profile2.survey_result.update!(
      goal_title: 'JavaScript学習',
      goal_description: 'Reactの入門を学ぶ'
    )
    create(:goal, user: user, survey_profile: survey_profile2)

    survey_profile3 = create(:survey_profile, user: user)
    survey_profile3.survey_result.update!(
      goal_title: 'Python学習',
      goal_description: 'Djangoの入門を学ぶ'
    )
    create(:goal, user: user, survey_profile: survey_profile3)
  end

  describe 'オートコンプリート機能' do
    context '検索キーワードを入力した場合' do
      it 'Ruby を入力すると候補が表示される', js: true do
        # 目標一覧ページに遷移（パスは適宜変更してください）
        visit goals_path

        # ページが表示されるまで待機
        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        # JavaScript の読み込みを待つ
        expect(page).to have_css('#q', wait: 10)

        # 検索フォームに入力
        fill_in 'q', with: 'Ruby'

        # オートコンプリートの候補が表示されるまで待機
        expect(page).to have_css('.suggestion-item', text: 'Ruby学習', wait: 5)
      end

      it 'Rails を入力すると候補が表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: 'Rails'

        expect(page).to have_css('.suggestion-item', text: 'Ruby学習', wait: 5)
      end

      it 'React を入力すると候補が表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: 'React'

        expect(page).to have_css('.suggestion-item', text: 'JavaScript学習', wait: 5)
      end
    end

    context '候補をクリックした場合' do
      it '検索結果が表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: 'Ruby'

        # 候補が表示されるまで待機
        expect(page).to have_css('.suggestion-item', text: 'Ruby学習', wait: 5)

        # 候補をクリック
        find('.suggestion-item', text: 'Ruby学習').click

        # 検索結果が表示される
        expect(page).to have_content('Ruby学習'), '検索結果が表示されません'
        expect(page).not_to have_content('JavaScript学習'), 'JavaScript学習が表示されています'
        expect(page).not_to have_content('Python学習'), 'Python学習が表示されています'
      end
    end

    context '部分一致検索' do
      it 'Rub を入力しても候補が表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: 'Rub'

        expect(page).to have_css('.suggestion-item', text: 'Ruby学習', wait: 5)
      end
    end

    context '大文字小文字を区別しない検索' do
      it 'ruby を入力しても候補が表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: 'ruby'

        expect(page).to have_css('.suggestion-item', text: 'Ruby学習', wait: 5)
      end
    end
  end

  describe 'エッジケーステスト' do
    context '空文字列で検索した場合' do
      it '全ての目標が表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: ''
        click_button '検索'

        expect(page).to have_content('Ruby学習'), 'Ruby学習が表示されません'
        expect(page).to have_content('JavaScript学習'), 'JavaScript学習が表示されません'
        expect(page).to have_content('Python学習'), 'Python学習が表示されません'
      end
    end

    context '検索結果が0件の場合' do
      it '「検索結果が見つかりませんでした」と表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: '存在しないキーワード'
        click_button '検索'

        expect(page).to have_content('まだ成長の星⭐が見つかっていません'), 'エラーメッセージが表示されません'
        expect(page).not_to have_content('Ruby学習'), 'Ruby学習が表示されています'
        expect(page).not_to have_content('JavaScript学習'), 'JavaScript学習が表示されています'
        expect(page).not_to have_content('Python学習'), 'Python学習が表示されています'
      end
    end

    context '複数のキーワードで検索した場合' do
      it 'Ruby Rails を入力すると候補が表示される', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: 'Ruby Rails'

        expect(page).to have_css('.suggestion-item', text: 'Ruby学習', wait: 5)
      end
    end

    context '候補が表示されない場合' do
      it '該当する候補がない場合、候補が表示されない', js: true do
        visit goals_path

        expect(page).to have_content('成長の星 一覧'), '成長の星 一覧ページが表示されません'

        fill_in 'q', with: 'PHP'

        expect(page).not_to have_css('.suggestion-item', wait: 5)
      end
    end
  end
end
