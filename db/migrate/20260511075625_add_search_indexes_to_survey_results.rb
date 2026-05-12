class AddSearchIndexesToSurveyResults < ActiveRecord::Migration[7.0]
  def change
    # goal_title カラムにインデックスを追加
    add_index :survey_results, :goal_title
    
    # goal_description カラムにインデックスを追加
    add_index :survey_results, :goal_description, length: 255
    
    # survey_profile_id と goal_title の複合インデックス
    # （よく使う組み合わせ）
    add_index :survey_results, [:survey_profile_id, :goal_title]
  end
end
