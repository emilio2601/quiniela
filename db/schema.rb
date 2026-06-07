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

ActiveRecord::Schema[8.1].define(version: 2026_06_07_031711) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "matches", force: :cascade do |t|
    t.integer "away_score"
    t.string "away_team", null: false
    t.datetime "created_at", null: false
    t.bigint "external_id"
    t.integer "home_score"
    t.string "home_team", null: false
    t.datetime "kickoff_at", null: false
    t.integer "number", null: false
    t.string "outcome"
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_matches_on_external_id", unique: true
    t.index ["kickoff_at"], name: "index_matches_on_kickoff_at"
    t.index ["number"], name: "index_matches_on_number", unique: true
    t.index ["status"], name: "index_matches_on_status"
  end

  create_table "picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "match_id", null: false
    t.integer "prediction", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["match_id"], name: "index_picks_on_match_id"
    t.index ["user_id", "match_id"], name: "index_picks_on_user_id_and_match_id", unique: true
    t.index ["user_id"], name: "index_picks_on_user_id"
  end

  create_table "poll_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error"
    t.boolean "ok", default: true, null: false
    t.integer "resolved"
    t.integer "scored"
    t.integer "unmatched"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_poll_runs_on_created_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_users_on_name", unique: true
  end

  add_foreign_key "picks", "matches"
  add_foreign_key "picks", "users"
end
