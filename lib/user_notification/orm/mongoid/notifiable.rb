module UserNotification
  module ORM
    module Mongoid
      module Notifiable
        def self.extended(base)
          base.has_many :notifications, :class_name => "::UserNotification::Notification", :as => :notifiable
        end
      end
    end
  end
end
