module UserNotification
  module ORM
    module Mongoid
      class Adapter
        # Creates the notification on `trackable` with `options`
        def self.create_notification(trackable, options)
          trackable.notifications.create options
        end
      end
    end
  end
end
