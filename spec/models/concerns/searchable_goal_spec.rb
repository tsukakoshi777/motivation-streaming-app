# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchableGoal, type: :model do
  describe '検索機能' do
    # ユーザーを作成
    let(:user) { create(:user) }

    # goal1 用のデータ作成
    let!(:goal1) do
      survey_profile1 = create(:survey_profile, user: user)
      # survey_result は自動作成されるので、明示的に作成する必要はない
      # ただし、goal_title と goal_description をカスタマイズしたい場合は、
      # 自動作成された survey_result を更新する
      survey_profile1.survey_result.update!(
        goal_title: 'Ruby学習',
        goal_description: 'Railsの入門を学ぶ'
      )
      create(:goal, user: user, survey_profile: survey_profile1)
    end

    # goal2 用のデータ作成
    let!(:goal2) do
      survey_profile2 = create(:survey_profile, user: user)
      survey_profile2.survey_result.update!(
        goal_title: 'JavaScript学習',
        goal_description: 'Reactの入門を学ぶ'
      )
      create(:goal, user: user, survey_profile: survey_profile2)
    end

    # goal3 用のデータ作成
    let!(:goal3) do
      survey_profile3 = create(:survey_profile, user: user)
      survey_profile3.survey_result.update!(
        goal_title: 'Python学習',
        goal_description: 'Djangoの入門を学ぶ'
      )
      create(:goal, user: user, survey_profile: survey_profile3)
    end

    describe '.search_by_keyword' do
      context '正常系' do
        context 'タイトルで検索' do
          it 'Ruby を含む目標が検索される' do
            results = Goal.search_by_keyword('Ruby')
            expect(results).to include(goal1)
            expect(results).not_to include(goal2, goal3)
          end
        end

        context '説明文で検索' do
          it 'Rails を含む目標が検索される' do
            results = Goal.search_by_keyword('Rails')
            expect(results).to include(goal1)
            expect(results).not_to include(goal2, goal3)
          end
        end

        context '部分一致検索' do
          it 'Rub を含む目標が検索される' do
            results = Goal.search_by_keyword('Rub')
            expect(results).to include(goal1)
            expect(results).not_to include(goal2, goal3)
          end
        end

        context '大文字小文字を区別しない検索' do
          it 'ruby を含む目標が検索される' do
            results = Goal.search_by_keyword('ruby')
            expect(results).to include(goal1)
            expect(results).not_to include(goal2, goal3)
          end
        end
      end

      context 'エッジケース' do
        context '空文字列で検索' do
          it '全ての目標が返される' do
            results = Goal.search_by_keyword('')
            expect(results).to include(goal1, goal2, goal3)
          end
        end

        context 'nil で検索' do
          it '全ての目標が返される' do
            results = Goal.search_by_keyword(nil)
            expect(results).to include(goal1, goal2, goal3)
          end
        end

        context '検索結果が0件' do
          it '空の配列が返される' do
            results = Goal.search_by_keyword('存在しないキーワード')
            expect(results).to be_empty
          end
        end
      end
    end
  end
end
