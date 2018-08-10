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

ActiveRecord::Schema.define(version: 2018_08_07_200804) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "locations", force: :cascade do |t|
    t.bigint "store_id"
    t.string "name", default: "", null: false
    t.string "address"
    t.string "country"
    t.string "state"
    t.string "city"
    t.string "email", default: "", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zip"
    t.text "custom_html"
    t.index ["store_id"], name: "index_locations_on_store_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "store_id"
    t.bigint "location_id"
    t.string "customer_name", default: "", null: false
    t.string "customer_email", default: "", null: false
    t.string "customer_phone"
    t.string "platform_product_id"
    t.string "platform_variant_id"
    t.text "instructions_from_customer"
    t.boolean "fulfilled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_reservations_on_location_id"
    t.index ["store_id"], name: "index_reservations_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "platform_store_id"
    t.string "public_key"
    t.string "secret_key"
    t.string "name"
    t.text "top_msg"
    t.text "success_msg"
    t.text "email_template"
    t.boolean "show_phone", default: true
    t.boolean "show_instructions_from_customer", default: true
    t.index ["shopify_domain"], name: "index_stores_on_shopify_domain", unique: true
  end

end
