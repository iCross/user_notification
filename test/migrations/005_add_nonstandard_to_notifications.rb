class AddNonstandardToNotifications < ActiveRecord::Migration
  def change
    change_table :notifications do |t|
      t.string :nonstandard
    end
  end
end
