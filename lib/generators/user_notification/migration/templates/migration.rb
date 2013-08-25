# Migration responsible for creating a table with notifications
class CreateNotifications < ActiveRecord::Migration
  # Create table
  def self.up
    create_table :notifications do |t|
      t.belongs_to :trackable, :polymorphic => true
      t.belongs_to :owner, :polymorphic => true
      t.string  :key
      t.text    :parameters
      t.belongs_to :recipient, :polymorphic => true
      t.boolwan :read, default: false

      t.timestamps
    end

    add_index :notifications, [:trackable_id, :trackable_type]
    add_index :notifications, [:owner_id, :owner_type]
    add_index :notifications, [:recipient_id, :recipient_type]
  end
  # Drop table
  def self.down
    drop_table :notifications
  end
end
