# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171217221817) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "galleries", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "category",         limit: 255, default: "general"
    t.integer  "user_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "pic_file_name",    limit: 255
    t.string   "pic_content_type", limit: 255
    t.integer  "pic_file_size"
    t.datetime "pic_updated_at"
  end

  create_table "host_haulers", force: :cascade do |t|
    t.integer  "driver_id"
    t.date     "haul_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pages", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.text     "content"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "riders", force: :cascade do |t|
    t.integer  "host_hauler_id"
    t.integer  "user_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "resource_id"
    t.string   "resource_type", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "shift_logs", force: :cascade do |t|
    t.datetime "change_date"
    t.integer  "user_id"
    t.integer  "shift_id"
    t.string   "action_taken"
    t.text     "note"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "shift_types", force: :cascade do |t|
    t.string   "short_name",  limit: 255, null: false
    t.string   "description", limit: 255, null: false
    t.string   "start_time",  limit: 255
    t.string   "end_time",    limit: 255
    t.string   "tasks",       limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "shift_types", ["short_name"], name: "index_shift_types_on_short_name", using: :btree

  create_table "shifts", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "shift_type_id",                           null: false
    t.integer  "shift_status_id",             default: 1, null: false
    t.date     "shift_date"
    t.string   "day_of_week",     limit: 255
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "short_name"
  end

  add_index "shifts", ["shift_date"], name: "index_shifts_on_shift_date", using: :btree
  add_index "shifts", ["user_id"], name: "index_shifts_on_user_id", using: :btree

  create_table "surveys", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "date"
    t.integer  "count"
    t.integer  "type1"
    t.integer  "type2"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sys_configs", force: :cascade do |t|
    t.integer  "season_year"
    t.integer  "group_1_year"
    t.integer  "group_2_year"
    t.integer  "group_3_year"
    t.date     "season_start_date"
    t.date     "bingo_start_date"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "shift_count"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "name",                   limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.string   "street",                 limit: 255
    t.string   "city",                   limit: 255
    t.string   "state",                  limit: 255
    t.string   "zip",                    limit: 255
    t.string   "home_phone",             limit: 255
    t.string   "cell_phone",             limit: 255
    t.string   "alt_email",              limit: 255
    t.integer  "start_year"
    t.text     "notes"
    t.boolean  "confirmed"
    t.boolean  "active_user"
    t.string   "nickname",               limit: 255
    t.integer  "snowbird_start_year"
    t.string   "head_shot",              limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["name"], name: "index_users_on_name", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

end
