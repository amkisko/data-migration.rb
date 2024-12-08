ActiveRecord::Schema.define(version: 2024_12_06_200411) do
  create_table :data_migration_tasks, force: true do |t|
    t.string "name", null: false

    t.json "kwargs", default: {}, null: false
    t.json "current_jobs", default: {}, null: false

    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"

    t.bigint "operator_id"
    t.string "operator_type"

    t.integer "pause_minutes", default: 0, null: false
    t.integer "jobs_limit"

    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table :users, force: true do |t|
    t.string :email
    t.string :version
  end
end
