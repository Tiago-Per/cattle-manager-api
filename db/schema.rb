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

ActiveRecord::Schema[8.1].define(version: 2026_09_13_200100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "animals", force: :cascade do |t|
    t.date "birth_date"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "identification", null: false
    t.string "sex", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["identification"], name: "index_animals_on_identification", unique: true
    t.index ["user_id"], name: "index_animals_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "animal_id", null: false
    t.datetime "created_at", null: false
    t.date "due_on"
    t.string "event_type", null: false
    t.text "notes"
    t.date "occurred_on", null: false
    t.string "product_name"
    t.string "sire_identification"
    t.datetime "updated_at", null: false
    t.decimal "weight_kg", precision: 6, scale: 2
    t.index ["animal_id", "occurred_on"], name: "index_events_on_animal_id_and_occurred_on"
    t.index ["due_on"], name: "index_events_on_due_on"
  end

  create_table "reminders_sent", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.date "window_end", null: false
    t.date "window_start", null: false
    t.index ["user_id", "window_start", "window_end"], name: "index_reminders_sent_on_user_and_window", unique: true
    t.index ["user_id"], name: "index_reminders_sent_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.string "phone_number"
    t.datetime "updated_at", null: false
    t.boolean "whatsapp_opt_in", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
  end

  add_foreign_key "animals", "users"
  add_foreign_key "events", "animals"
  add_foreign_key "reminders_sent", "users"
end
