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

ActiveRecord::Schema[8.1].define(version: 2026_04_24_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ads", force: :cascade do |t|
    t.string "ad_type", default: "direct", null: false
    t.integer "clicks_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "impressions_count", default: 0, null: false
    t.string "link_target", default: "_blank"
    t.string "link_url"
    t.string "name", null: false
    t.string "placement_zone", null: false
    t.integer "priority", default: 0, null: false
    t.text "script_code"
    t.string "sponsor_label"
    t.datetime "starts_at"
    t.string "status", default: "active", null: false
    t.bigint "target_category_id"
    t.bigint "target_location_id"
    t.datetime "updated_at", null: false
    t.index ["placement_zone"], name: "index_ads_on_placement_zone"
    t.index ["status"], name: "index_ads_on_status"
    t.index ["target_category_id"], name: "index_ads_on_target_category_id"
    t.index ["target_location_id"], name: "index_ads_on_target_location_id"
  end

  create_table "article_locations", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "location_id"], name: "index_article_locations_on_article_id_and_location_id", unique: true
    t.index ["article_id"], name: "index_article_locations_on_article_id"
    t.index ["location_id"], name: "index_article_locations_on_location_id"
  end

  create_table "article_sources", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["article_id", "position"], name: "index_article_sources_on_article_id_and_position"
    t.index ["article_id"], name: "index_article_sources_on_article_id"
  end

  create_table "article_tags", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "tag_id"], name: "index_article_tags_on_article_id_and_tag_id", unique: true
    t.index ["article_id"], name: "index_article_tags_on_article_id"
    t.index ["tag_id"], name: "index_article_tags_on_tag_id"
  end

  create_table "article_translations", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.text "dek"
    t.string "locale", null: false
    t.text "meta_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "locale"], name: "index_article_translations_on_article_id_and_locale", unique: true
    t.index ["article_id"], name: "index_article_translations_on_article_id"
    t.index ["locale", "slug"], name: "index_article_translations_on_locale_and_slug", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "article_type", default: "news"
    t.bigint "author_id", null: false
    t.boolean "breaking", default: false, null: false
    t.string "canonical_url"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "dek"
    t.boolean "featured", default: false, null: false
    t.string "featured_image_alt"
    t.string "featured_image_caption"
    t.text "ja_search_text", default: ""
    t.text "meta_description"
    t.datetime "published_at"
    t.tsvector "search_vector"
    t.string "seo_title"
    t.string "slug"
    t.text "source_notes"
    t.string "status", default: "draft", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["ja_search_text"], name: "index_articles_on_ja_search_text_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["search_vector"], name: "index_articles_on_search_vector", using: :gin
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.bigint "resource_id"
    t.string "resource_label"
    t.string "resource_type", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "authors", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "role_title"
    t.string "slug"
    t.string "twitter_url"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "website_url"
    t.index ["slug"], name: "index_authors_on_slug", unique: true
    t.index ["user_id"], name: "index_authors_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "position"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "ip_address"
    t.string "name", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_comments_on_article_id"
  end

  create_table "contact_submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message"
    t.string "name"
    t.boolean "read", default: false, null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["read"], name: "index_contact_submissions_on_read"
  end

  create_table "locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_locations_on_slug", unique: true
  end

  create_table "newsletter_issues", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "locale", default: "en", null: false
    t.integer "recipients_count", default: 0
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["locale"], name: "index_newsletter_issues_on_locale"
  end

  create_table "newsletter_subscribers", force: :cascade do |t|
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "unsubscribe_token"
    t.datetime "unsubscribed_at"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_newsletter_subscribers_on_confirmation_token", unique: true
    t.index ["email"], name: "index_newsletter_subscribers_on_email", unique: true
    t.index ["unsubscribe_token"], name: "index_newsletter_subscribers_on_unsubscribe_token", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.string "value_type", default: "string", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "site_languages", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.boolean "deletable", default: true, null: false
    t.string "flag_emoji"
    t.string "name", null: false
    t.string "native_name"
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active", "position"], name: "index_site_languages_on_active_and_position"
    t.index ["code"], name: "index_site_languages_on_code", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "static_pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "meta_description"
    t.string "seo_title"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_static_pages_on_slug", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "tip_submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.boolean "read", default: false, null: false
    t.text "tip_body", null: false
    t.datetime "updated_at", null: false
    t.index ["read"], name: "index_tip_submissions_on_read"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.string "role"
    t.datetime "totp_enabled_at"
    t.string "totp_secret"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ads", "categories", column: "target_category_id"
  add_foreign_key "ads", "locations", column: "target_location_id"
  add_foreign_key "article_locations", "articles"
  add_foreign_key "article_locations", "locations"
  add_foreign_key "article_sources", "articles"
  add_foreign_key "article_tags", "articles"
  add_foreign_key "article_tags", "tags"
  add_foreign_key "article_translations", "articles"
  add_foreign_key "articles", "authors"
  add_foreign_key "articles", "categories"
  add_foreign_key "authors", "users"
  add_foreign_key "comments", "articles"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
