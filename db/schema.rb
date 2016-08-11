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

ActiveRecord::Schema.define(version: 20160805212509) do

  create_table "autocases", primary_key: "record_date", id: :datetime, default: -> { "CURRENT_TIMESTAMP" }, force: :cascade, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8" do |t|
    t.integer "sprint",    null: false
    t.integer "cases",     null: false
    t.integer "automated", null: false
    t.index ["sprint"], name: "sprint", using: :btree
  end

  create_table "locks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", comment: "InnoDB free: 0 kB" do |t|
    t.string   "namespace"
    t.string   "resource",   null: false
    t.string   "owner",      null: false
    t.datetime "expires",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace", "resource"], name: "index_ownthat_test_locks_on_namespace_and_resource", unique: true, using: :btree
  end

end
