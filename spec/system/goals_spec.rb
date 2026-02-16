# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Goals', type: :system do
  let(:user) { create(:user) }
  let(:streaming_platform) { create(:streaming_platform) }
  let(:streaming_category) { create(:streaming_category) }
  let(:streaming_experience) { create(:streaming_experience) }

  let!(:survey_profile1) do
    create(:survey_profile,
           user: user,
           streaming_platform: streaming_platform,
           streaming_category: streaming_category,
           streaming_experience: streaming_experience)
  end

  let!(:goal1) { create(:goal, user: user, survey_profile: survey_profile1) }

  let!(:survey_profile2) do
    create(:survey_profile,
           user: user,
           streaming_platform: streaming_platform,
           streaming_category: streaming_category,
           streaming_experience: streaming_experience)
  end

  let!(:goal2) { create(:goal, user: user, survey_profile: survey_profile2) }

  before do
    # ログイン処理
    visit login_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'password' # Factoryで設定したパスワードを指定
    click_button 'ログイン'
  end

  describe '一覧機能' do
    context '目標が存在する場合' do
      it '目標の一覧が表示される' do
        visit goals_path

        # survey_profileの情報を使って表示を確認
        expect(page).to have_content(streaming_platform.name)
        expect(page).to have_content(streaming_category.name)
      end
    end

    context '目標が0件の場合' do
      before do
        Goal.destroy_all
      end

      it 'メッセージが表示される' do
        visit goals_path
        expect(page).to have_content('まだ成長の星⭐が見つかっていません')
      end
    end
  end
end
