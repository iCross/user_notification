module UserNotification
  # Provides association for notifications bound to this object by *trackable*.
  module Trackable
    # Delegates to ORM.
    def self.included(base)
      base.extend UserNotification::inherit_orm("Trackable")
    end
  end
end
