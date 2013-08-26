require 'generators/user_notification'
require 'rails/generators/active_record'

module UserNotification
  module Generators
    # Notification generator that creates notification model file from template
    class ModelGenerator < ActiveRecord::Generators::Base
      extend Base

      argument :name, :type => :string, :default => 'model'
      # Create model in project's folder
      def generate_files
        copy_file 'notification.rb', "app/models/notification.rb"
        copy_file 'notifying.rb', "app/models/notifying.rb"
      end
    end
  end
end
