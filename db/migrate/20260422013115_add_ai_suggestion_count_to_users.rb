class AddAiSuggestionCountToUsers < ActiveRecord::Migration[7.0]
  def change
     add_column :users, :ai_suggestion_count, :integer, default: 0, null: false
  end
end
