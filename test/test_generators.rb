require 'test_helper'
  require 'rails/generators/test_case'
  require 'generators/user_notification/model/model_generator'
  require 'generators/user_notification/migration/migration_generator'

class TestNotificationGenerator < Rails::Generators::TestCase
  tests UserNotification::Generators::ModelGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  def test_generating_notification_models
    run_generator
    assert_file "app/models/notification.rb"
    assert_file "app/models/notifying.rb"
  end
end

class TestMigrationGenerator < Rails::Generators::TestCase
  tests UserNotification::Generators::MigrationGenerator
  destination File.expand_path("../tmp", File.dirname(__FILE__))
  setup :prepare_destination

  def test_generating_notification_model
    run_generator
    assert_migration "db/migrate/create_notifications.rb"
    assert_migration "db/migrate/create_notifyings.rb"
  end
end

