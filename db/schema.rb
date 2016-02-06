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

ActiveRecord::Schema.define(version: 20160205164801) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.datetime "created_at",  default: '2016-01-30 00:00:31'
  end

  add_index "people", ["industry"], name: "index_people_on_industry", using: :btree
  add_index "people", ["location"], name: "index_people_on_location", using: :btree
  add_index "people", ["name"], name: "index_people_on_name", using: :btree
  add_index "people", ["position"], name: "index_people_on_position", using: :btree

  create_table "users", force: :cascade do |t|
    t.string  "dir"
    t.integer "industry"
    t.string  "login"
    t.string  "password"
    t.string  "proxy"
    t.string  "comment"
    t.string  "linkedin_profile"
    t.string  "command_str"
  end

end
