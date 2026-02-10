class CreateGoals < ActiveRecord::Migration[7.0]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :survey_profile, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end