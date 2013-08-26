# Migration responsible for creating a table with notifications
class CreateNotifications < ActiveRecord::Migration
  # Create table
  def self.up
    create_table :notifications do |t|
      t.belongs_to :notifiable, :polymorphic => true
      t.belongs_to :owner, :polymorphic => true
      t.string  :key
      t.text    :parameters
      t.belongs_to :recipient, :polymorphic => true

      t.timestamps
    end

    add_index :notifications, [:notifiable_id, :notifiable_type]
    add_index :notifications, [:owner_id, :owner_type]
    add_index :notifications, [:recipient_id, :recipient_type]
  end
  # Drop table
  def self.down
    drop_table :notifications
  end
end
