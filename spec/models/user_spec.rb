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
      # ← 1回目の作成(一意のメールアドレスを使う)
      existing_user = create(:user)

      # ← 2回目の作成(同じメールアドレスを使う)
      user = build(:user, email: existing_user.email)
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

  describe 'AI提案の利用回数制限' do
    let(:user) { create(:user) }

    describe '#can_use_ai_suggestion?' do
      context '利用回数が上限未満の場合' do
        it 'trueを返す' do
          expect(user.can_use_ai_suggestion?).to be true
        end
      end

      context '利用回数が上限に達した場合' do
        before do
          user.update!(
            ai_suggestion_count: User::AI_SUGGESTION_LIMIT,
            ai_suggestion_reset_date: Date.current
          )
          user.reload
        end

        it 'falseを返す' do
          expect(user.can_use_ai_suggestion?).to be false
        end
      end

      context '日付が変わった場合' do
        before do
          user.update!(
            ai_suggestion_count: User::AI_SUGGESTION_LIMIT,
            ai_suggestion_reset_date: Date.yesterday
          )
          user.reload
        end

        it 'カウントがリセットされてtrueを返す' do
          expect(user.can_use_ai_suggestion?).to be true
          user.reload
          expect(user.ai_suggestion_count).to eq 0 # ← 追加: カウントがリセットされることを確認
          expect(user.ai_suggestion_reset_date).to eq Date.current # ← 追加: リセット日時が今日になることを確認
        end
      end
    end

    describe '#remaining_ai_suggestion_count' do
      context '利用回数が0の場合' do
        it '上限回数を返す' do
          expect(user.remaining_ai_suggestion_count).to eq User::AI_SUGGESTION_LIMIT
        end
      end

      context '利用回数が1の場合' do
        before do
          user.update!(
            ai_suggestion_count: 1,
            ai_suggestion_reset_date: Date.current
          )
          user.reload
        end

        it '残り回数を返す' do
          expect(user.remaining_ai_suggestion_count).to eq(User::AI_SUGGESTION_LIMIT - 1)
        end
      end

      context '利用回数が上限に達した場合' do
        before do
          user.update!(
            ai_suggestion_count: User::AI_SUGGESTION_LIMIT,
            ai_suggestion_reset_date: Date.current
          )
          user.reload
        end

        it '0を返す' do
          expect(user.remaining_ai_suggestion_count).to eq 0
        end
      end

      context '利用回数が上限を超えた場合' do
        before do
          user.update!(
            ai_suggestion_count: User::AI_SUGGESTION_LIMIT + 1,
            ai_suggestion_reset_date: Date.current
          )
          user.reload
        end

        it '0を返す(負の値にならない)' do
          expect(user.remaining_ai_suggestion_count).to eq 0
        end
      end

      context '日付が変わった場合' do
        before do
          user.update!(
            ai_suggestion_count: User::AI_SUGGESTION_LIMIT,
            ai_suggestion_reset_date: Date.yesterday
          )
          user.reload
        end

        it 'リセットされて上限回数を返す' do
          expect(user.remaining_ai_suggestion_count).to eq User::AI_SUGGESTION_LIMIT
          user.reload
          expect(user.ai_suggestion_count).to eq 0 # ← 追加: カウントがリセットされることを確認
          expect(user.ai_suggestion_reset_date).to eq Date.current # ← 追加: リセット日時が今日になることを確認
        end
      end
    end

    describe '#increment_ai_suggestion_count' do
      context '通常の場合' do
        it 'カウントが1増える' do
          expect { user.increment_ai_suggestion_count }.to change { user.reload.ai_suggestion_count }.by(1)
        end
      end
    end

    describe '#reset_ai_suggestion_count_if_needed' do
      context '日付が変わっていない場合' do
        before do
          user.update!(
            ai_suggestion_count: 2,
            ai_suggestion_reset_date: Date.current
          )
          user.reload
        end

        it 'カウントがリセットされない' do
          user.reset_ai_suggestion_count_if_needed
          user.reload
          expect(user.ai_suggestion_count).to eq 2
        end
      end

      context '日付が変わった場合' do
        before do
          user.update!(
            ai_suggestion_count: User::AI_SUGGESTION_LIMIT,
            ai_suggestion_reset_date: Date.yesterday
          )
          user.reload
        end

        it 'カウントが0にリセットされる' do
          user.reset_ai_suggestion_count_if_needed
          user.reload
          expect(user.ai_suggestion_count).to eq 0
        end

        it 'リセット日時が今日になる' do
          user.reset_ai_suggestion_count_if_needed
          user.reload
          expect(user.ai_suggestion_reset_date).to eq Date.current
        end
      end
    end
  end
end
