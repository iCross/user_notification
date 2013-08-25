module UserNotification
  module ORM
    module Mongoid
      module Trackable
        def self.extended(base)
          base.has_many :notifications, :class_name => "::UserNotification::Notification", :as => :trackable
        end
      end
    end
  end
end
