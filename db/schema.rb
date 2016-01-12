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

ActiveRecord::Schema.define(version: 20160105142934) do

  create_table "people", force: :cascade do |t|
    t.string  "name"
    t.string  "position"
    t.string  "industry"
    t.string  "location"
    t.integer "linkedin_id"
    t.string  "email"
    t.text    "notes"
  end

  add_index "people", ["industry"], name: "index_people_on_industry"
  add_index "people", ["location"], name: "index_people_on_location"
  add_index "people", ["name"], name: "index_people_on_name"
  add_index "people", ["position"], name: "index_people_on_position"

end
