module UserNotification
  module ORM
    module ActiveRecord
      # Implements {UserNotification::Trackable} for ActiveRecord
      # @see UserNotification::Trackable
      module Trackable
        # Creates an association for notifications where self is the *trackable*
        # object.
        def self.extended(base)
          base.has_many :notifications, :class_name => "::UserNotification::Notification", :as => :trackable
        end
      end
    end
  end
end
