module UserNotification
  # Handles creation of Activities upon destruction and update of tracked model.
  module Creation
    extend ActiveSupport::Concern

    included do
      after_create :notification_on_create
    end
    private
      # Creates notification upon creation of the tracked model
      def notification_on_create
        create_notification(:create)
      end
  end
end
