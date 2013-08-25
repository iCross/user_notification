require 'generators/user_notification'
require 'rails/generators/active_record'

module UserNotification
  module Generators
    # Notification generator that creates notification model file from template
    class NotificationGenerator < ActiveRecord::Generators::Base
      extend Base

      argument :name, :type => :string, :default => 'notification'
      # Create model in project's folder
      def generate_files
        copy_file 'notification.rb', "app/models/#{name}.rb"
      end
    end
  end
end
