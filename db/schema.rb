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

ActiveRecord::Schema.define(version: 2020_10_08_083747) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

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
    t.text "details"
    t.string "platform_location_id"
    t.string "product_tag_filter"
    t.boolean "visible_in_cart", default: true
    t.boolean "visible_in_product", default: true
    t.index ["store_id", "platform_location_id"], name: "index_locations_on_store_id_and_platform_location_id"
    t.index ["store_id"], name: "index_locations_on_store_id"
  end

  create_table "plans", force: :cascade do |t|
    t.float "price"
    t.string "name"
    t.jsonb "features"
    t.jsonb "limits"
    t.string "code"
    t.integer "trial_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plans_on_code"
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
    t.text "line_item"
    t.jsonb "cart"
    t.jsonb "additional_fields", default: {}
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
    t.text "customer_confirm_email_tpl"
    t.boolean "show_phone", default: true
    t.boolean "show_instructions_from_customer", default: true
    t.boolean "active", default: false
    t.boolean "customer_confirm_email_tpl_enabled", default: false
    t.boolean "reserve_modal_tpl_enabled", default: false
    t.text "reserve_modal_tpl"
    t.boolean "choose_location_modal_tpl_enabled", default: false
    t.text "choose_location_modal_tpl"
    t.string "reserve_product_btn_action", default: "auto"
    t.string "reserve_product_btn_selector"
    t.text "reserve_product_btn_tpl"
    t.text "reserve_modal_faq_tpl"
    t.boolean "reserve_modal_faq_tpl_enabled", default: false
    t.boolean "reserve_product_btn_tpl_enabled", default: false
    t.text "custom_css"
    t.boolean "custom_css_enabled", default: false
    t.text "stock_status_tpl"
    t.boolean "stock_status_tpl_enabled", default: false
    t.string "stock_status_selector"
    t.string "stock_status_action", default: "auto"
    t.string "stock_status_behavior_when_stock_unknown", default: "unknown_stock_hide_button"
    t.string "stock_status_behavior_when_no_location_selected", default: "unknown_stock_show_button"
    t.string "stock_status_behavior_when_no_nearby_locations_and_no_location", default: "show_first_available"
    t.jsonb "webhooks"
    t.text "reserve_cart_btn_tpl"
    t.boolean "reserve_cart_btn_tpl_enabled", default: false
    t.string "reserve_cart_btn_selector"
    t.string "reserve_cart_btn_action", default: "auto"
    t.boolean "show_when_only_available_online", default: true
    t.string "customer_confirmation_subject"
    t.string "location_notification_subject"
    t.jsonb "flags"
    t.boolean "location_notification_email_tpl_enabled", default: false
    t.text "location_notification_email_tpl"
    t.string "customer_confirmation_sender_name"
    t.string "location_notification_sender_name"
    t.jsonb "plan_overrides"
    t.datetime "last_connected_at"
    t.text "connection_error"
    t.boolean "show_additional_fields", default: false
    t.boolean "webhooks_enabled"
    t.index ["shopify_domain"], name: "index_stores_on_shopify_domain", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "store_id"
    t.string "remote_id"
    t.jsonb "plan_attributes"
    t.jsonb "custom_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["remote_id"], name: "index_subscriptions_on_remote_id"
    t.index ["store_id"], name: "index_subscriptions_on_store_id"
  end

  create_table "uninstallations", force: :cascade do |t|
    t.integer "store_id"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.integer "store_id"
    t.string "name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "flags"
    t.index ["email"], name: "index_users_on_email"
    t.index ["store_id"], name: "index_users_on_store_id"
  end

end
