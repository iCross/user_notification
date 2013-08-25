module UserNotification
  module ORM
    module ActiveRecord
      # Implements {UserNotification::Notifiable} for ActiveRecord
      # @see UserNotification::Notifiable
      module Notifiable
        # Creates an association for notifications where self is the *notifiable*
        # object.
        def self.extended(base)
          base.has_many :notifications, :class_name => "::UserNotification::Notification", :as => :notifiable
        end
      end
    end
  end
end
