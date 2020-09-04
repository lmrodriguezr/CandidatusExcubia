# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_04_000500) do

  create_table "authors", force: :cascade do |t|
    t.string "given"
    t.string "family"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["given", "family"], name: "index_authors_on_given_and_family", unique: true
  end

  create_table "names", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_names_on_name", unique: true
  end

  create_table "publication_authors", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "author_id"
    t.string "sequence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_publication_authors_on_author_id"
    t.index ["publication_id", "author_id"], name: "index_publication_authors_on_publication_id_and_author_id", unique: true
    t.index ["publication_id"], name: "index_publication_authors_on_publication_id"
  end

  create_table "publication_names", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "name_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name_id"], name: "index_publication_names_on_name_id"
    t.index ["publication_id", "name_id"], name: "index_publication_names_on_publication_id_and_name_id", unique: true
    t.index ["publication_id"], name: "index_publication_names_on_publication_id"
  end

  create_table "publication_subjects", force: :cascade do |t|
    t.integer "publication_id"
    t.integer "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id", "subject_id"], name: "index_publication_subjects_on_publication_id_and_subject_id", unique: true
    t.index ["publication_id"], name: "index_publication_subjects_on_publication_id"
    t.index ["subject_id"], name: "index_publication_subjects_on_subject_id"
  end

  create_table "publications", force: :cascade do |t|
    t.string "title"
    t.string "journal"
    t.string "journal_loc"
    t.date "journal_date"
    t.string "doi"
    t.string "url"
    t.string "crossref_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pub_type"
    t.string "abstract"
    t.index ["doi"], name: "index_publications_on_doi", unique: true
  end

  create_table "subjects", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_subjects_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "username", null: false
    t.string "affiliation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.boolean "contributor", default: false
    t.text "contributor_statement"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

end
