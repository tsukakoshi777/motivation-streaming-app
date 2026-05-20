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
      # 同じ user を使う(循環参照を避けるため)
      user = create(:user)
      survey_profile = create(:survey_profile, user: user)

      # 最初の goal を作成
      create(:goal, user: user, survey_profile: survey_profile)

      # 同じ survey_profile を使って2つ目の goal を作成しようとする
      goal = build(:goal, user: user, survey_profile: survey_profile)

      expect(goal).to be_invalid
      expect(goal.errors[:survey_profile_id]).to include('はすでに存在します')
    end
  end

  # グラフ用データの取得テスト
  describe 'グラフ用データの取得' do
    let(:user) { create(:user) }
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

      # goal1に輝きメモを5件作成
      create_list(:spark, 5, goal: goal1, user: user)

      # goal2に輝きメモを10件作成
      create_list(:spark, 10, goal: goal2, user: user)

      # goal3に輝きメモを3件作成
      create_list(:spark, 3, goal: goal3, user: user)
    end

    it '目標別の輝きメモ件数が正しく取得できる' do
      # ユーザーの目標を取得
      goals = user.goals.includes(:sparks)

      # 目標別の輝きメモ件数を集計
      goal_data = goals.map do |goal|
        { goal_title: goal.survey_profile.survey_result.goal_title, sparks_count: goal.sparks.count }
      end

      # 期待される結果
      expected_data = [
        { goal_title: 'テスト目標1', sparks_count: 5 },
        { goal_title: 'テスト目標2', sparks_count: 10 },
        { goal_title: 'テスト目標3', sparks_count: 3 }
      ]

      expect(goal_data).to match_array(expected_data)
    end
  end
end
