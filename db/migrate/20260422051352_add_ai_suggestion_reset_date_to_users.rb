class AddAiSuggestionResetDateToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :ai_suggestion_reset_date, :date
  end
end
