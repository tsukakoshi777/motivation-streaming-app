# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles', type: :system do
  let(:user) { create(:user) }

  before do
    # テスト用ファイルを作成
    create_test_image
    create_invalid_file

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

  describe 'プロフィール表示機能' do
    context 'ログインしている場合' do
      before do
        visit profile_path
      end

      it 'プロフィールページが表示される' do
        expect(page).to have_content('プロフィール')
      end

      it 'ユーザーのニックネームが表示される' do
        expect(page).to have_content(user.nickname)
      end

      it 'ユーザーのメールアドレスが表示される' do
        expect(page).to have_content(user.email)
      end

      it '編集ボタンが表示される' do
        expect(page).to have_link('編集', href: edit_profile_path)
      end
    end
  end

  describe 'プロフィール編集機能' do
    context 'ログインしている場合' do
      before do
        visit edit_profile_path
      end

      it 'プロフィール編集ページが表示される' do
        expect(page).to have_content('プロフィール編集')
      end

      it 'ニックネームのフォームが表示される' do
        expect(page).to have_field('user[nickname]', with: user.nickname)
      end

      it 'メールアドレスのフォームが表示される' do
        expect(page).to have_field('user[email]', with: user.email)
      end

      it 'アバター画像のフォームが表示される' do
        expect(page).to have_field('user[avatar]')
      end
    end
  end

  describe 'プロフィール更新機能' do
    context 'ログインしている場合' do
      before do
        visit edit_profile_path
      end

      context '有効なパラメータの場合' do
        it 'ニックネームが更新される' do
          fill_in 'user[nickname]', with: '新しいニックネーム'
          click_button '更新'

          # フラッシュメッセージを確認
          expect(page).to have_content('プロフィールを更新しました')

          # プロフィールページにリダイレクトされる
          expect(current_path).to eq(profile_path)

          # 更新後のニックネームが表示される
          expect(page).to have_content('新しいニックネーム')
        end

        it 'メールアドレスが更新される' do
          fill_in 'user[email]', with: 'new_email@example.com'
          click_button '更新'

          # フラッシュメッセージを確認
          expect(page).to have_content('プロフィールを更新しました')

          # プロフィールページにリダイレクトされる
          expect(current_path).to eq(profile_path)

          # 更新後のメールアドレスが表示される
          expect(page).to have_content('new_email@example.com')
        end
      end

      context '無効なパラメータの場合' do
        it 'ニックネームが空の場合、更新に失敗する' do
          fill_in 'user[nickname]', with: ''
          click_button '更新'

          # エラーメッセージが表示される
          expect(page).to have_content('プロフィールの更新に失敗しました')

          # 編集ページが再表示される
          expect(current_path).to eq(edit_profile_path)
        end

        it 'メールアドレスが空の場合、更新に失敗する' do
          fill_in 'user[email]', with: ''
          click_button '更新'

          # エラーメッセージが表示される
          expect(page).to have_content('プロフィールの更新に失敗しました')

          # 編集ページが再表示される
          expect(current_path).to eq(edit_profile_path)
        end

        it 'ニックネームが50文字を超える場合、更新に失敗する' do
          fill_in 'user[nickname]', with: 'a' * 51
          click_button '更新'

          # エラーメッセージが表示される
          expect(page).to have_content('プロフィールの更新に失敗しました')

          # 編集ページが再表示される
          expect(current_path).to eq(edit_profile_path)
        end

        it '登録済みのメールアドレスを入力した場合、更新に失敗する' do
          # 別のユーザーを作成
          another_user = create(:user, email: 'another@example.com')

          fill_in 'user[email]', with: another_user.email
          click_button '更新'

          # エラーメッセージが表示される
          expect(page).to have_content('プロフィールの更新に失敗しました')

          # 編集ページが再表示される
          expect(current_path).to eq(edit_profile_path)
        end
      end
    end
  end

  describe 'アバター画像のアップロード機能' do
    context 'ログインしている場合' do
      before do
        visit edit_profile_path
      end

      context '有効な画像ファイルの場合' do
        it 'アバター画像がアップロードされる' do
          # テスト用の画像ファイルを準備
          image_path = Rails.root.join('spec/fixtures/test_avatar.png')

          # 画像ファイルをアップロード
          attach_file 'user[avatar]', image_path

          click_button '更新'

          # フラッシュメッセージを確認
          expect(page).to have_content('プロフィールを更新しました')

          # プロフィールページにリダイレクトされる
          expect(current_path).to eq(profile_path)

          # アップロードした画像が表示される
          expect(page).to have_selector("img[src*='test_avatar.png']")
        end
      end

      context '無効な画像ファイルの場合' do
        it '許可されていない拡張子の場合、アップロードに失敗する' do
          # テスト用の無効なファイルを準備
          invalid_file_path = Rails.root.join('spec/fixtures/test_file.txt')

          # 無効なファイルをアップロード
          attach_file 'user[avatar]', invalid_file_path

          click_button '更新'

          # エラーメッセージが表示される
          expect(page).to have_content('プロフィールの更新に失敗しました')

          # 編集ページが再表示される
          expect(current_path).to eq(edit_profile_path)
        end

        it 'ファイルサイズが5MBを超える場合、アップロードに失敗する' do
          # 5MBを超える画像ファイルを作成（ダミー）
          large_image_path = Rails.root.join('tmp/large_avatar.png')

          # 6MBのダミーファイルを生成
          File.binwrite(large_image_path, '0' * 6.megabytes)

          # 5MBを超えるファイルをアップロード
          attach_file 'user[avatar]', large_image_path

          click_button '更新'

          # エラーメッセージが表示される
          expect(page).to have_content('プロフィールの更新に失敗しました')

          # 編集ページが再表示される
          expect(current_path).to eq(edit_profile_path)

          # 生成した画像ファイルを削除
          FileUtils.rm_f(large_image_path)
        end
      end

      context 'アバター画像の削除' do
        it 'アバター画像を削除できる' do
          # 事前にアバター画像をアップロード
          image_path = Rails.root.join('spec/fixtures/test_avatar.png')
          user.update!(avatar: File.open(image_path))

          visit edit_profile_path

          # 削除チェックボックスをチェック
          check 'user[remove_avatar]'

          click_button '更新'

          # フラッシュメッセージを確認
          expect(page).to have_content('プロフィールを更新しました')

          # プロフィールページにリダイレクトされる
          expect(current_path).to eq(profile_path)

          # アバター画像が削除される
          expect(page).not_to have_selector("img[src*='test_avatar.png']")
        end
      end
    end
  end
end
