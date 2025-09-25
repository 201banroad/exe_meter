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

ActiveRecord::Schema[8.0].define(version: 2025_09_18_140706) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "sessions", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "total_seconds"
    t.integer "target_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "target_hours", precision: 8, scale: 2
  end

  create_table "work_intervals", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "duration_sec"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_work_intervals_on_session_id"
  end

  add_foreign_key "work_intervals", "sessions"
end
