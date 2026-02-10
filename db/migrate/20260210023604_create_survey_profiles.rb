class CreateSurveyProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :survey_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :streaming_platform, null: false, foreign_key: true
      t.references :streaming_category, null: false, foreign_key: true
      t.references :streaming_experience, null: false, foreign_key: true
      t.integer :weekly_frequency, null: false, comment: '週の配信頻度(回数)'
      t.integer :average_listeners, null: false, comment: '平均視聴者数'
      t.integer :total_listeners, comment: '累計視聴者数(おおよその人数)'
      t.integer :listener_dropout_rate, null: false, comment: '視聴者の離脱率(%)'
      t.integer :motivation_level, null: false, comment: 'モチベーションレベル(1〜5)'

      t.timestamps
    end

  end
end
