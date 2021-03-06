module UserNotification
  # Module extending classes that serve as owners
  module Activist
    extend ActiveSupport::Concern

    # Module extending classes that serve as owners
    module ClassMethods
      # Adds ActiveRecord associations to model to simplify fetching
      # so you can list notifications performed by the owner.
      # It is completely optional. Any model can be an owner to an notification
      # even without being an explicit acts_as_activist.
      #
      # == Usage:
      # In model:
      #
      #   class User < ActiveRecord::Base
      #     include UserNotification::Model
      #     acts_as_activist
      #   end
      #
      # In controller:
      #   User.first.notifications
      #
      def acts_as_activist
        # Association of notifications as their owner.
        # @!method notifications_as_owner
        # @return [Array<Notification>] Activities which self is the owner of.
        has_many :notifications_as_owner, :class_name => "Notification", :as => :owner

        has_many :notifyings, :foreign_key => 'recipient_id'
        # Association of notifications as their recipient.
        # @!method notifications_as_recipient
        # @return [Array<Notification>] Activities which self is the recipient of.
        has_many :notifications_as_recipient, :through => :notifyings, :source => :notification, :class_name => "Notification"  do
          def unread
            where('notifyings.read' => false)
          end
        end
      end
    end
  end
end
