module UserNotification
  # Implements {UserNotification::Notifiable} for ActiveRecord
  # @see UserNotification::Notifiable
  module Notifiable
    # Creates an association for notifications where self is the *notifiable*
    # object.
    extend ActiveSupport::Concern

    included do
      has_many :notifications, :as => :notifiable
    end
  end
end
