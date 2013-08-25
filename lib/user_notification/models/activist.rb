module UserNotification
  # Provides helper methods for selecting notifications from a user.
  module Activist
    # Delegates to configured ORM.
    def self.included(base)
      base.extend UserNotification::inherit_orm("Activist")
    end
  end
end
