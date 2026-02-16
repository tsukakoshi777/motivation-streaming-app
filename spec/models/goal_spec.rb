# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Goal, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }
    it { should belong_to(:survey_profile) }
  end

  describe 'バリデーション' do
    it '有効なファクトリを持つこと' do
      goal = build(:goal)
      expect(goal).to be_valid
    end

    it 'ユーザーがいなければ無効' do
      goal = build(:goal, user: nil)
      expect(goal).to be_invalid
      expect(goal.errors[:user]).to include('を入力してください')
    end

    it 'survey_profile がいなければ無効' do
      goal = build(:goal, survey_profile: nil)
      expect(goal).to be_invalid
      expect(goal.errors[:survey_profile]).to include('を入力してください')
    end

    it 'survey_profile_id が重複していれば無効' do
      # 同じ user を使う（循環参照を避けるため）
      user = create(:user)
      survey_profile = create(:survey_profile, user: user)
      create(:goal, user: user, survey_profile: survey_profile)

      # 別の survey_profile を作成
      create(:survey_profile, user: user)
      goal = build(:goal, user: user, survey_profile: survey_profile)

      expect(goal).to be_invalid
      expect(goal.errors[:survey_profile_id]).to include('はすでに存在します')
    end
  end
end
