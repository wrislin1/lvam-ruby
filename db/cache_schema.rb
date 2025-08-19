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

ActiveRecord::Schema[8.0].define(version: 2025_07_18_164325) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "event_status", ["pending", "processing", "processed", "failed"]
  create_enum "user_download_status", ["pending", "processing", "complete", "failed"]
  create_enum "user_status", ["active", "archived", "blocked"]

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

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "events", force: :cascade do |t|
    t.json "data", null: false
    t.string "source", null: false
    t.text "processing_errors"
    t.enum "status", default: "pending", null: false, enum_type: "event_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "report_columns", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.string "title", limit: 255, null: false
    t.string "subtitle", limit: 255, default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", null: false
    t.string "col_type"
    t.index ["report_id", "position"], name: "index_report_columns_on_report_id_and_position", unique: true
    t.index ["report_id"], name: "index_report_columns_on_report_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", limit: 255, null: false
    t.string "subtitle1", limit: 255, default: ""
    t.string "subtitle2", limit: 255, default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_reports_on_title"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "user_downloads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "downloadable_type"
    t.bigint "downloadable_id"
    t.enum "status", default: "pending", null: false, enum_type: "user_download_status"
    t.string "error_message"
    t.string "progress_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["downloadable_type", "downloadable_id"], name: "index_user_downloads_on_downloadable"
    t.index ["user_id"], name: "index_user_downloads_on_user_id"
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_id", null: false
    t.string "payment_method_id"
    t.string "product_id"
    t.string "price_id"
    t.integer "amount"
    t.datetime "current_period_start", precision: nil
    t.datetime "current_period_end", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_user_subscriptions_on_status"
    t.index ["user_id", "stripe_id"], name: "index_user_subscriptions_on_user_id_and_stripe_id", unique: true
    t.index ["user_id"], name: "index_user_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "admin", default: false, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "stripe_id"
    t.enum "status", default: "active", null: false, enum_type: "user_status"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["object"], name: "index_versions_on_object", using: :gin
    t.index ["object_changes"], name: "index_versions_on_object_changes", using: :gin
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "report_columns", "reports", on_delete: :cascade
  add_foreign_key "reports", "users", on_delete: :cascade
  add_foreign_key "user_downloads", "users"
  add_foreign_key "user_subscriptions", "users"
end
