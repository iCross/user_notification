module UserNotification
  module ORM
    module Mongoid
      class Adapter
        # Creates the notification on `notifiable` with `options`
        def self.create_notification(notifiable, options)
          notifiable.notifications.create options
        end
      end
    end
  end
end
