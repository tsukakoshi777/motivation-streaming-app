class CreateStreamingCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :streaming_categories do |t|
      t.string :name, null: false

      t.timestamps
    end
    
    # データベースレベルでユニーク制約を追加
    add_index :streaming_categories, :name, unique: true
  end
end
