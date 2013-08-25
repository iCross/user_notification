module UserNotification
  # Handles creation of Activities upon destruction of notifiable model.
  module Destruction
    extend ActiveSupport::Concern

    included do
      before_destroy :notification_on_destroy
    end
    private
      # Records an notification upon destruction of the notifiable model
      def notification_on_destroy
        create_notification(:destroy)
      end
  end
end
