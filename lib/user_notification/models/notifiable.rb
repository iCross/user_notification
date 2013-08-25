module UserNotification
  # Provides association for notifications bound to this object by *notifiable*.
  module Notifiable
    # Delegates to ORM.
    def self.included(base)
      base.extend UserNotification::inherit_orm("Notifiable")
    end
  end
end
