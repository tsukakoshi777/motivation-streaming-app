class CreateSurveyResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :survey_responses do |t|
      t.references :survey_profile, null: false, foreign_key: true, index: { unique: true }
      t.text :happy_moment
      t.text :sad_moment
      t.text :streaming_reasons
      t.text :streaming_reasons_other
      t.text :desired_streaming_style
      t.text :desired_listener
      t.integer :desired_monthly_income

      t.timestamps
    end
  end
end
