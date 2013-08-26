module UserNotification
  module ORM
    module ActiveRecord
      # The ActiveRecord model containing
      # details about recorded notification.
      class Notification < ::ActiveRecord::Base
        include Renderable

        # Define polymorphic association to the parent
        belongs_to :notifiable, :polymorphic => true
        # Define ownership to a resource responsible for this notification
        belongs_to :owner, :polymorphic => true
        # Define ownership to a resource targeted by this notification
        has_many :recipients, :through => :notifyings
        has_many :notifyings, class_name: '::UserNotification::Notifying'
        # Serialize parameters Hash
        serialize :parameters, Hash

        if ::ActiveRecord::VERSION::MAJOR < 4
          attr_accessible :key, :owner, :parameters, :recipients, :notifiable
        end
      end
    end
  end
end
