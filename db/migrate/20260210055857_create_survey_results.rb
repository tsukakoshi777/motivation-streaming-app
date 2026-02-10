class CreateSurveyResults < ActiveRecord::Migration[7.0]
  def change
    create_table :survey_results do |t|
      t.references :survey_profile, null: false, foreign_key: true, index: { unique: true }
      t.integer :goal_source, null: false, default: 1
      t.string :goal_title
      t.text :goal_description
      t.text :ai_goal_suggestion
      t.text :ai_improvement_suggestion

      t.timestamps
    end
  end
end
