require 'mongoid'

module UserNotification
  module ORM
    module Mongoid
      # The ActiveRecord model containing
      # details about recorded notification.
      class Notification
        include ::Mongoid::Document
        include ::Mongoid::Timestamps
        include ::Mongoid::Attributes::Dynamic if (::Mongoid::VERSION =~ /^4/) == 0
        include Renderable

        # Define polymorphic association to the parent
        belongs_to :notifiable,  polymorphic: true
        # Define ownership to a resource responsible for this notification
        belongs_to :owner,      polymorphic: true
        # Define ownership to a resource targeted by this notification
        belongs_to :recipient,  polymorphic: true

        field :key,         type: String
        field :parameters,  type: Hash
      end
    end
  end
end
