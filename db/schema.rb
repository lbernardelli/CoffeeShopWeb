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

ActiveRecord::Schema[8.0].define(version: 2025_10_07_175519) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "coffee_variants", force: :cascade do |t|
    t.bigint "coffee_id", null: false
    t.string "size", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coffee_id", "size"], name: "index_coffee_variants_on_coffee_id_and_size", unique: true
    t.index ["coffee_id"], name: "index_coffee_variants_on_coffee_id"
  end

  create_table "coffees", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "roast_type"
    t.string "origin"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_coffees_on_active"
    t.index ["name"], name: "index_coffees_on_name"
    t.index ["roast_type"], name: "index_coffees_on_roast_type"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "coffee_variant_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coffee_variant_id"], name: "index_order_items_on_coffee_variant_id"
    t.index ["order_id", "coffee_variant_id"], name: "index_order_items_on_order_id_and_coffee_variant_id", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status", default: "cart", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shipping_name"
    t.text "shipping_address"
    t.string "shipping_city"
    t.string "shipping_state"
    t.string "shipping_zip"
    t.string "shipping_country"
    t.string "payment_method"
    t.string "payment_transaction_id"
    t.index ["user_id", "status"], name: "index_orders_on_user_id_and_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "coffee_variants", "coffees"
  add_foreign_key "order_items", "coffee_variants"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "sessions", "users"
end
