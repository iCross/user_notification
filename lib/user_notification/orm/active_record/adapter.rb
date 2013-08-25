module UserNotification
  module ORM
    # Support for ActiveRecord for UserNotification. Used by default and supported
    # officialy.
    module ActiveRecord
      # Provides ActiveRecord specific, database-related routines for use by
      # UserNotification.
      class Adapter
        # Creates the notification on `trackable` with `options`
        def self.create_notification(trackable, options)
          trackable.notifications.create options
        end
      end
    end
  end
end
