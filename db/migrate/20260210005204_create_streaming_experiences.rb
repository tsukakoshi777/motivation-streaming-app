class CreateStreamingExperiences < ActiveRecord::Migration[7.0]
  def change
    create_table :streaming_experiences do |t|
      t.string :name, null: false

      t.timestamps
    end
    
    # データベースレベルでユニーク制約を追加
    add_index :streaming_experiences, :name, unique: true
  end
end
