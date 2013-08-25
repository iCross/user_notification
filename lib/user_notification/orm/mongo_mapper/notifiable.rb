module UserNotification
  module ORM
    module MongoMapper
      module Notifiable
        def self.extended(base)
          base.many :notifications, :class_name => "::UserNotification::Notification", order: :created_at.asc, :as => :notifiable
        end
      end
    end
  end
end
