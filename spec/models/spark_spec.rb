# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spark, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    it '有効なファクトリを持つこと' do
      spark = build(:spark, goal: goal)
      expect(spark).to be_valid
    end

    it '内容が必須であること' do
      spark = build(:spark, goal: goal, content: nil)
      expect(spark).not_to be_valid
      expect(spark.errors[:content]).to include('を入力してください')
    end

    it '内容が500文字以内であること' do
      spark = build(:spark, goal: goal, content: 'a' * 501)
      expect(spark).not_to be_valid
      expect(spark.errors[:content]).to include('は500文字以内で入力してください')
    end

    it '内容が500文字であれば有効であること' do
      spark = build(:spark, goal: goal, content: 'a' * 500)
      expect(spark).to be_valid
    end
  end

  describe 'アソシエーション' do
    it 'goalに属すること' do
      association = described_class.reflect_on_association(:goal)
      expect(association.macro).to eq :belongs_to
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    it '新しい順に並ぶこと' do
      spark1 = create(:spark, goal: goal, created_at: 1.day.ago)
      spark2 = create(:spark, goal: goal, created_at: 2.days.ago)
      spark3 = create(:spark, goal: goal, created_at: Time.current)

      expect(goal.sparks.order(created_at: :desc)).to eq [spark3, spark1, spark2]
    end
  end

  # グラフ用データの取得テスト
  describe 'グラフ用データの取得' do
    let(:user) { create(:user) }
    let!(:survey_profile) { create(:survey_profile, user: user) }
    let!(:goal) { create(:goal, user: user, survey_profile: survey_profile) }

    before do
      survey_profile.survey_result.update!(goal_title: 'テスト目標', goal_description: 'テスト説明')

      # 1月に3件作成
      create_list(:spark, 3, goal: goal, user: user, created_at: Time.zone.local(2025, 1, 15))

      # 2月に5件作成
      create_list(:spark, 5, goal: goal, user: user, created_at: Time.zone.local(2025, 2, 15))

      # 3月に2件作成
      create_list(:spark, 2, goal: goal, user: user, created_at: Time.zone.local(2025, 3, 15))
    end

    it '月別の輝きメモ件数が正しく取得できる' do
      # 月別の輝きメモ件数を集計（PostgreSQL対応版）
      monthly_data = user.sparks
                         .unscoped # ← default_scopeを無効化
                         .group(Arel.sql("TO_CHAR(created_at AT TIME ZONE 'Asia/Tokyo', 'YYYY年MM月')"))
                         .count
                         .sort # Ruby側でソート

      # 期待される結果
      expected_data = {
        '2025年01月' => 3,
        '2025年02月' => 5,
        '2025年03月' => 2
      }

      expect(monthly_data.to_h).to eq(expected_data)
    end
  end
end
