module UserNotification
  module ORM
    module MongoMapper
      # Module extending classes that serve as owners
      module Activist
        extend ActiveSupport::Concern

        def self.extended(base)
          base.extend(ClassMethods)
        end
        # Association of notifications as their owner.
        # @!method notifications
        # @return [Array<Notification>] Activities which self is the owner of.

        # Association of notifications as their recipient.
        # @!method private_notifications
        # @return [Array<Notification>] Activities which self is the recipient of.

        # Module extending classes that serve as owners
        module ClassMethods
          # Adds MongoMapper associations to model to simplify fetching
          # so you can list notifications performed by the owner.
          # It is completely optional. Any model can be an owner to an notification
          # even without being an explicit activist.
          #
          # == Usage:
          # In model:
          #
          #   class User
          #     include MongoMapper::Document
          #     include UserNotification::Model
          #     activist
          #   end
          #
          # In controller:
          #   User.first.notifications
          #
          def activist
            many :notifications_as_owner,      :class_name => "::UserNotification::Notification", :as => :owner
            many :notifications_as_recipient,  :class_name => "::UserNotification::Notification", :as => :recipient
          end
        end
      end
    end
  end
end
