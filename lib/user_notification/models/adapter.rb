module UserNotification
  # Loads database-specific routines for use by UserNotification.
  class Adapter
    def self.create_notification(notifiable, options)
      notifiable.notifications.create options
    end
  end
end
