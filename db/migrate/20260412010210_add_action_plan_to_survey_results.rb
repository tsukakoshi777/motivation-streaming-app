class AddActionPlanToSurveyResults < ActiveRecord::Migration[7.0]
  def change
    add_column :survey_results, :action_plan, :text
  end
end
