ActiveRecord::Schema.define(:version => 0) do

  create_table "tasks", :force => true do |t|
    t.string   "name"
    t.integer  "status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "name"
    t.integer  "status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "posts", :force => true do |t|
    t.string   "name"
    t.integer  "status_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "statuses", :force => true do |t|
    t.string   "name"
    t.string   "title"
    t.integer  "position"
    t.boolean  "default"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
