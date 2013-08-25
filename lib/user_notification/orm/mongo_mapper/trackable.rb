module UserNotification
  module ORM
    module MongoMapper
      module Trackable
        def self.extended(base)
          base.many :notifications, :class_name => "::UserNotification::Notification", order: :created_at.asc, :as => :trackable
        end
      end
    end
  end
end
