if ENV["PA_ORM"] == "active_record"

  require 'test_helper'
  require 'rails/generators/test_case'
  require 'generators/user_notification/notification/notification_generator'
  require 'generators/user_notification/migration/migration_generator'

  class TestNotificationGenerator < Rails::Generators::TestCase
    tests UserNotification::Generators::NotificationGenerator
    destination File.expand_path("../tmp", File.dirname(__FILE__))
    setup :prepare_destination

    def test_generating_notification_model
      run_generator
      assert_file "app/models/notification.rb"
    end
  end

  class TestMigrationGenerator < Rails::Generators::TestCase
    tests UserNotification::Generators::MigrationGenerator
    destination File.expand_path("../tmp", File.dirname(__FILE__))
    setup :prepare_destination

    def test_generating_notification_model
      run_generator
      assert_migration "db/migrate/create_notifications.rb"
    end
  end

end
