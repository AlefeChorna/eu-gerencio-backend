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

ActiveRecord::Schema[8.0].define(version: 2025_05_13_027450) do
  create_table "companies", force: :cascade do |t|
    t.string "trader_name", null: false
    t.integer "entity_id", null: false
    t.integer "parent_id"
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_companies_on_admin_id"
    t.index ["entity_id"], name: "index_companies_on_entity_id"
    t.index ["parent_id"], name: "index_companies_on_parent_id"
  end

  create_table "entities", force: :cascade do |t|
    t.string "registration_number", null: false
    t.string "registration_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["registration_number", "registration_type"], name: "index_entities_on_registration_number_and_registration_type", unique: true
  end

  create_table "people", force: :cascade do |t|
    t.string "name", null: false
    t.string "family_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.integer "entity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_id"], name: "index_people_on_entity_id"
    t.index ["name", "family_name", "email"], name: "index_people_on_name_and_family_name_and_email", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.integer "entity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_id"], name: "index_users_on_entity_id"
  end

  add_foreign_key "companies", "companies", column: "parent_id"
  add_foreign_key "companies", "entities"
  add_foreign_key "companies", "users", column: "admin_id"
  add_foreign_key "people", "entities"
  add_foreign_key "users", "entities"
end
