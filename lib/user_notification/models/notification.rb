module UserNotification
  class Notification < ActiveRecord::Base
    # The ActiveRecord model containing
    # details about recorded notification.
    include Renderable

    # Define polymorphic association to the parent
    belongs_to :notifiable, :polymorphic => true
    # Define ownership to a resource responsible for this notification
    belongs_to :owner, :polymorphic => true
    # Define ownership to a resource targeted by this notification
    has_many :recipients, :through => :notifyings
    has_many :notifyings
    # Serialize parameters Hash
    serialize :parameters, Hash

    def mark_as_read_for!(recipient)
      self.notifyings.where(recipient: recipient).update_all(read: true)
    end

    def read_by?(recipient)
      self.notifyings.where(recipient: recipient).first.read?
    end
  end
end


