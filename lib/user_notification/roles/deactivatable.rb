module UserNotification
  # Enables per-class disabling of UserNotification functionality.
  module Deactivatable
    extend ActiveSupport::Concern

    included do
      class_attribute :user_notification_enabled_for_model
      set_user_notification_class_defaults
    end

    # Returns true if UserNotification is enabled
    # globally and for this class.
    # @return [Boolean]
    # @api private
    # @since 0.5.0
    # overrides the method from Common
    def user_notification_enabled?
      UserNotification.enabled? && self.class.user_notification_enabled_for_model
    end

    # Provides global methods to disable or enable UserNotification on a per-class
    # basis.
    module ClassMethods
      # Switches user_notification off for this class
      def user_notification_off
        self.user_notification_enabled_for_model = false
      end

      # Switches user_notification on for this class
      def user_notification_on
        self.user_notification_enabled_for_model = true
      end

      # @since 1.0.0
      # @api private
      def set_user_notification_class_defaults
        super
        self.user_notification_enabled_for_model = true
      end
    end
  end
end
