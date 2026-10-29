class CreateWebNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :web_notifications do |t|
      t.integer :user_id, null: false
      t.integer :actor_id
      t.integer :project_id
      t.string :notifiable_type, limit: 30
      t.integer :notifiable_id
      t.string :kind, limit: 30, null: false
      t.string :title, null: false
      t.string :summary, limit: 500
      t.string :path, limit: 1000, null: false
      t.datetime :read_at
      t.datetime :created_on, null: false
    end
    add_index :web_notifications, [:user_id, :id]
    add_index :web_notifications, [:user_id, :read_at]
    add_index :web_notifications, :created_on
  end
end
