require 'rails/generators/named_base'

module UserNotification
  # A generator module with Notification table schema.
  module Generators
    # A base module
    module Base
      # Get path for migration template
      def source_root
        @_user_notification_source_root ||= File.expand_path(File.join('../user_notification', generator_name, 'templates'), __FILE__)
      end
    end
  end
end
