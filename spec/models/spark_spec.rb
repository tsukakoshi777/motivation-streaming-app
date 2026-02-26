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
end
