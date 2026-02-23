class CreateSparks < ActiveRecord::Migration[7.0]
  def change
    create_table :sparks do |t|
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.references :goal, null: false, foreign_key: true

      t.timestamps
    end
  end
end
