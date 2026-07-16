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

ActiveRecord::Schema[7.2].define(version: 2026_07_16_143812) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "owner_id"
    t.bigint "renter_id"
    t.string "status"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "rental_days"
    t.integer "rental_amount"
    t.integer "cleaning_fee"
    t.integer "delivery_fee"
    t.integer "deposit_amount"
    t.integer "discount_amount"
    t.decimal "platform_fee_rate"
    t.integer "platform_fee_amount"
    t.integer "owner_earning_amount"
    t.integer "total_amount"
    t.string "pickup_method"
    t.text "pickup_address"
    t.text "return_address"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "cancelled_at"
    t.datetime "picked_up_at"
    t.datetime "returned_at"
    t.datetime "completed_at"
    t.text "cancel_reason"
    t.text "reject_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "renter_service_fee_rate"
    t.integer "renter_service_fee_amount"
    t.index ["owner_id"], name: "index_bookings_on_owner_id"
    t.index ["product_id", "start_time", "end_time"], name: "index_bookings_on_product_id_and_start_time_and_end_time"
    t.index ["product_id"], name: "index_bookings_on_product_id"
    t.index ["renter_id"], name: "index_bookings_on_renter_id"
    t.index ["status"], name: "index_bookings_on_status"
  end

  create_table "disputes", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "opened_by_id"
    t.string "reason"
    t.text "description"
    t.string "status"
    t.text "resolution_note"
    t.bigint "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_disputes_on_booking_id"
    t.index ["opened_by_id"], name: "index_disputes_on_opened_by_id"
    t.index ["resolved_by_id"], name: "index_disputes_on_resolved_by_id"
    t.index ["status"], name: "index_disputes_on_status"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "payer_id"
    t.integer "amount"
    t.string "payment_method"
    t.string "status"
    t.string "transaction_id"
    t.datetime "paid_at"
    t.text "admin_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["payer_id"], name: "index_payments_on_payer_id"
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "payouts", force: :cascade do |t|
    t.bigint "owner_id"
    t.bigint "booking_id", null: false
    t.integer "amount"
    t.string "status"
    t.string "payout_method"
    t.datetime "paid_at"
    t.text "admin_note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payouts_on_booking_id"
    t.index ["owner_id"], name: "index_payouts_on_owner_id"
    t.index ["status"], name: "index_payouts_on_status"
  end

  create_table "product_condition_reports", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "product_id", null: false
    t.bigint "user_id", null: false
    t.string "report_type"
    t.string "status"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_product_condition_reports_on_booking_id"
    t.index ["product_id"], name: "index_product_condition_reports_on_product_id"
    t.index ["user_id"], name: "index_product_condition_reports_on_user_id"
  end

  create_table "product_reservations", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "booking_id", null: false
    t.bigint "renter_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_product_reservations_on_booking_id"
    t.index ["product_id", "start_time", "end_time"], name: "idx_on_product_id_start_time_end_time_2ae7c17081"
    t.index ["product_id"], name: "index_product_reservations_on_product_id"
    t.index ["renter_id"], name: "index_product_reservations_on_renter_id"
    t.index ["status"], name: "index_product_reservations_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "owner_id"
    t.string "title"
    t.string "product_type"
    t.text "description"
    t.string "status"
    t.string "condition_status"
    t.string "size"
    t.string "color"
    t.string "gender"
    t.string "age_group"
    t.string "brand"
    t.integer "price_per_day"
    t.integer "deposit_amount"
    t.integer "cleaning_fee"
    t.integer "replacement_value"
    t.text "address"
    t.string "city"
    t.string "district"
    t.string "ward"
    t.boolean "pickup_available"
    t.boolean "delivery_available"
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_products_on_city"
    t.index ["owner_id"], name: "index_products_on_owner_id"
    t.index ["product_type"], name: "index_products_on_product_type"
    t.index ["status"], name: "index_products_on_status"
  end

  create_table "promotion_redemptions", force: :cascade do |t|
    t.bigint "promotion_id", null: false
    t.bigint "user_id", null: false
    t.bigint "booking_id", null: false
    t.integer "discount_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_promotion_redemptions_on_booking_id"
    t.index ["promotion_id"], name: "index_promotion_redemptions_on_promotion_id"
    t.index ["user_id"], name: "index_promotion_redemptions_on_user_id"
  end

  create_table "promotions", force: :cascade do |t|
    t.bigint "owner_id"
    t.string "code"
    t.string "discount_type"
    t.decimal "discount_value"
    t.integer "max_discount_amount"
    t.integer "min_order_amount"
    t.integer "usage_limit"
    t.integer "used_count"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_promotions_on_code", unique: true
    t.index ["owner_id"], name: "index_promotions_on_owner_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "reviewer_id"
    t.bigint "reviewee_id"
    t.bigint "product_id", null: false
    t.integer "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_reviews_on_booking_id"
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name"
    t.string "phone"
    t.string "role"
    t.string "status"
    t.string "preferred_locale"
    t.text "address"
    t.string "city"
    t.string "district"
    t.string "ward"
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "tiktok_url"
    t.string "zalo_url"
    t.string "website_url"
    t.string "bank_name"
    t.string "bank_account_name"
    t.string "bank_account_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["preferred_locale"], name: "index_users_on_preferred_locale"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "products"
  add_foreign_key "bookings", "users", column: "owner_id"
  add_foreign_key "bookings", "users", column: "renter_id"
  add_foreign_key "disputes", "bookings"
  add_foreign_key "disputes", "users", column: "opened_by_id"
  add_foreign_key "disputes", "users", column: "resolved_by_id"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "users", column: "payer_id"
  add_foreign_key "payouts", "bookings"
  add_foreign_key "payouts", "users", column: "owner_id"
  add_foreign_key "product_condition_reports", "bookings"
  add_foreign_key "product_condition_reports", "products"
  add_foreign_key "product_condition_reports", "users"
  add_foreign_key "product_reservations", "bookings"
  add_foreign_key "product_reservations", "products"
  add_foreign_key "product_reservations", "users", column: "renter_id"
  add_foreign_key "products", "users", column: "owner_id"
  add_foreign_key "promotion_redemptions", "bookings"
  add_foreign_key "promotion_redemptions", "promotions"
  add_foreign_key "promotion_redemptions", "users"
  add_foreign_key "promotions", "users", column: "owner_id"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
end
