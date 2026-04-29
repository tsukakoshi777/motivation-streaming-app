# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2026_04_28_041434) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authentications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_authentications_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_authentications_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "survey_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_profile_id"], name: "index_goals_on_survey_profile_id", unique: true
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "sparks", force: :cascade do |t|
    t.text "content"
    t.bigint "user_id", null: false
    t.bigint "goal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["goal_id"], name: "index_sparks_on_goal_id"
    t.index ["user_id"], name: "index_sparks_on_user_id"
  end

  create_table "streaming_categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_streaming_categories_on_name", unique: true
  end

  create_table "streaming_experiences", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_streaming_experiences_on_name", unique: true
  end

  create_table "streaming_platforms", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_streaming_platforms_on_name", unique: true
  end

  create_table "survey_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "streaming_platform_id", null: false
    t.bigint "streaming_category_id", null: false
    t.bigint "streaming_experience_id", null: false
    t.integer "weekly_frequency", null: false, comment: "週の配信頻度(回数)"
    t.integer "average_listeners", null: false, comment: "平均視聴者数"
    t.integer "total_listeners", comment: "累計視聴者数(おおよその人数)"
    t.integer "listener_dropout_rate", null: false, comment: "視聴者の離脱率(%)"
    t.integer "motivation_level", null: false, comment: "モチベーションレベル(1〜5)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["streaming_category_id"], name: "index_survey_profiles_on_streaming_category_id"
    t.index ["streaming_experience_id"], name: "index_survey_profiles_on_streaming_experience_id"
    t.index ["streaming_platform_id"], name: "index_survey_profiles_on_streaming_platform_id"
    t.index ["user_id"], name: "index_survey_profiles_on_user_id"
  end

  create_table "survey_responses", force: :cascade do |t|
    t.bigint "survey_profile_id", null: false
    t.text "happy_moment"
    t.text "sad_moment"
    t.text "streaming_reasons"
    t.text "streaming_reasons_other"
    t.text "desired_streaming_style"
    t.text "desired_listener"
    t.integer "desired_monthly_income"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_profile_id"], name: "index_survey_responses_on_survey_profile_id", unique: true
  end

  create_table "survey_results", force: :cascade do |t|
    t.bigint "survey_profile_id", null: false
    t.integer "goal_source", default: 1, null: false
    t.string "goal_title"
    t.text "goal_description"
    t.text "ai_goal_suggestion"
    t.text "ai_improvement_suggestion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "action_plan"
    t.index ["survey_profile_id"], name: "index_survey_results_on_survey_profile_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "nickname", null: false
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ai_suggestion_count", default: 0, null: false
    t.date "ai_suggestion_reset_date"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "authentications", "users"
  add_foreign_key "goals", "survey_profiles"
  add_foreign_key "goals", "users"
  add_foreign_key "sparks", "goals"
  add_foreign_key "sparks", "users"
  add_foreign_key "survey_profiles", "streaming_categories"
  add_foreign_key "survey_profiles", "streaming_experiences"
  add_foreign_key "survey_profiles", "streaming_platforms"
  add_foreign_key "survey_profiles", "users"
  add_foreign_key "survey_responses", "survey_profiles"
  add_foreign_key "survey_results", "survey_profiles"
end
