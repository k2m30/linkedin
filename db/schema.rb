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

ActiveRecord::Schema.define(version: 20160317092151) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "industries", force: :cascade do |t|
    t.integer  "index"
    t.string   "keywords"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "keywords", force: :cascade do |t|
    t.string  "owner"
    t.string  "position"
    t.string  "keyword"
    t.integer "industry"
    t.boolean "passed",   default: false
  end

  create_table "people", force: :cascade do |t|
    t.text     "name"
    t.text     "position"
    t.text     "industry"
    t.text     "location"
    t.integer  "linkedin_id"
    t.text     "email"
    t.text     "notes"
    t.string   "owner"
    t.datetime "created_at",  default: '2016-01-30 00:13:24'
    t.string   "passed_to"
  end

  add_index "people", ["industry"], name: "index_people_on_industry", using: :btree
  add_index "people", ["linkedin_id"], name: "index_people_on_linkedin_id", using: :btree
  add_index "people", ["location"], name: "index_people_on_location", using: :btree
  add_index "people", ["name"], name: "index_people_on_name", using: :btree
  add_index "people", ["position"], name: "index_people_on_position", using: :btree

  create_table "users", force: :cascade do |t|
    t.string  "dir"
    t.integer "industry_id"
    t.string  "login"
    t.string  "password"
    t.string  "proxy"
    t.string  "comment"
    t.string  "linkedin_profile"
    t.string  "command_str"
    t.boolean "paused",           default: false
  end

end
