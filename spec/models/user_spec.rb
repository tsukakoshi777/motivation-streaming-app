# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    it 'nickname, email, passwordがあれば有効' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'nicknameがなければ無効' do
      user = build(:user, nickname: nil)
      user.valid?
      expect(user.errors[:nickname]).to include('を入力してください')
    end

    it 'emailがなければ無効' do
      user = build(:user, email: nil)
      user.valid?
      expect(user.errors[:email]).to include('を入力してください')
    end

    it 'passwordがなければ無効' do
      user = build(:user, password: nil)
      user.valid?
      expect(user.errors[:password]).to include('を入力してください')
    end

    it 'passwordが6文字未満なら無効' do
      user = build(:user, password: '12345', password_confirmation: '12345')
      user.valid?
      expect(user.errors[:password]).to include('は6文字以上で入力してください')
    end

    it '重複したemailは無効' do
      create(:user, email: 'test@example.com')
      user = build(:user, email: 'test@example.com')
      user.valid?
      expect(user.errors[:email]).to include('はすでに存在します')
    end

    it 'nicknameが50文字を超えると無効' do
      user = build(:user, nickname: 'a' * 51)
      user.valid?
      expect(user.errors[:nickname]).to include('は50文字以内で入力してください')
    end
  end

  describe 'アソシエーション' do
    it 'SurveyProfileと関連付けられている' do
      association = described_class.reflect_on_association(:survey_profiles)
      expect(association.macro).to eq :has_many
    end

    it 'Goalと関連付けられている' do
      association = described_class.reflect_on_association(:goals)
      expect(association.macro).to eq :has_many
    end
  end
end
