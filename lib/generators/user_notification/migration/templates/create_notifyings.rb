class CreateNotifyings < ActiveRecord::Migration

  def change
    create_table :notifyings do |t|
      t.belongs_to :notification
      t.belongs_to :recipient
    end
  end

end
