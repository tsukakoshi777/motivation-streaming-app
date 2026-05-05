# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SurveyProfile, type: :model do
  describe 'バリデーション' do
    let(:user) { create(:user) }
    let(:survey_profile) { build(:survey_profile, user: user) }

    context '正常系' do
      it 'すべての属性が有効な場合、有効であること' do
        expect(survey_profile).to be_valid
      end
    end

    context '異常系' do
      it 'user_id がない場合、無効であること' do
        survey_profile.user = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:user]).to include('を入力してください')
      end

      it 'streaming_platform_id がない場合、無効であること' do
        survey_profile.streaming_platform = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:streaming_platform]).to include('を入力してください')
      end

      it 'streaming_category_id がない場合、無効であること' do
        survey_profile.streaming_category = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:streaming_category]).to include('を入力してください')
      end

      it 'streaming_experience_id がない場合、無効であること' do
        survey_profile.streaming_experience = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:streaming_experience]).to include('を入力してください')
      end

      it 'weekly_frequency がない場合、無効であること' do
        survey_profile.weekly_frequency = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:weekly_frequency]).to include('を入力してください')
      end

      it 'average_listeners がない場合、無効であること' do
        survey_profile.average_listeners = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:average_listeners]).to include('を入力してください')
      end

      it 'listener_dropout_rate がない場合、無効であること' do
        survey_profile.listener_dropout_rate = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:listener_dropout_rate]).to include('を入力してください')
      end

      it 'motivation_level がない場合、無効であること' do
        survey_profile.motivation_level = nil
        expect(survey_profile).to be_invalid
        expect(survey_profile.errors[:motivation_level]).to include('を入力してください')
      end
    end

    # ✅ エッジケーステストを追加
    context 'エッジケース' do
      describe 'motivation_level' do
        it '1 でも有効であること' do
          survey_profile.motivation_level = 1
          expect(survey_profile).to be_valid
        end

        it '5 でも有効であること' do
          survey_profile.motivation_level = 5
          expect(survey_profile).to be_valid
        end

        it '0 は無効であること（範囲外）' do
          survey_profile.motivation_level = 0
          expect(survey_profile).to be_invalid
          expect(survey_profile.errors[:motivation_level]).to include('は一覧にありません')
        end

        it '6 は無効であること（範囲外）' do
          survey_profile.motivation_level = 6
          expect(survey_profile).to be_invalid
          expect(survey_profile.errors[:motivation_level]).to include('は一覧にありません')
        end
      end

      describe 'weekly_frequency' do
        it '0 でも有効であること' do
          survey_profile.weekly_frequency = 0
          expect(survey_profile).to be_valid
        end

        it '大きな数でも有効であること' do
          survey_profile.weekly_frequency = 1000
          expect(survey_profile).to be_valid
        end

        it '負の数は無効であること' do
          survey_profile.weekly_frequency = -1
          expect(survey_profile).to be_invalid
          expect(survey_profile.errors[:weekly_frequency]).to include('は0以上の値にしてください')
        end
      end

      describe 'average_listeners' do
        it '0 でも有効であること' do
          survey_profile.average_listeners = 0
          expect(survey_profile).to be_valid
        end

        it '大きな数でも有効であること' do
          survey_profile.average_listeners = 1_000_000
          expect(survey_profile).to be_valid
        end

        it '負の数は無効であること' do
          survey_profile.average_listeners = -1
          expect(survey_profile).to be_invalid
          expect(survey_profile.errors[:average_listeners]).to include('は0以上の値にしてください')
        end
      end

      describe 'listener_dropout_rate' do
        it '0 でも有効であること' do
          survey_profile.listener_dropout_rate = 0
          expect(survey_profile).to be_valid
        end

        it '3 でも有効であること' do
          survey_profile.listener_dropout_rate = 3
          expect(survey_profile).to be_valid
        end

        it '負の数は無効であること' do
          survey_profile.listener_dropout_rate = -1
          expect(survey_profile).to be_invalid
          expect(survey_profile.errors[:listener_dropout_rate]).to include('は一覧にありません')
        end

        it '4 は無効であること（範囲外）' do
          survey_profile.listener_dropout_rate = 4
          expect(survey_profile).to be_invalid
          expect(survey_profile.errors[:listener_dropout_rate]).to include('は一覧にありません')
        end
      end
    end
  end
  describe 'アソシエーション' do
    it 'User に belongs_to で関連付けられていること' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end

    it 'StreamingPlatform に belongs_to で関連付けられていること' do
      association = described_class.reflect_on_association(:streaming_platform)
      expect(association.macro).to eq :belongs_to
    end

    it 'StreamingCategory に belongs_to で関連付けられていること' do
      association = described_class.reflect_on_association(:streaming_category)
      expect(association.macro).to eq :belongs_to
    end

    it 'StreamingExperience に belongs_to で関連付けられていること' do
      association = described_class.reflect_on_association(:streaming_experience)
      expect(association.macro).to eq :belongs_to
    end

    it 'SurveyResponse に has_one で関連付けられていること' do
      association = described_class.reflect_on_association(:survey_response)
      expect(association.macro).to eq :has_one
    end

    it 'SurveyResult に has_one で関連付けられていること' do
      association = described_class.reflect_on_association(:survey_result)
      expect(association.macro).to eq :has_one
    end

    it 'Goal に has_one で関連付けられていること' do
      association = described_class.reflect_on_association(:goal)
      expect(association.macro).to eq :has_one
    end
  end

  describe 'Factory' do
    it 'factory が有効であること' do
      survey_profile = create(:survey_profile)
      expect(survey_profile).to be_valid
    end
  end
end
