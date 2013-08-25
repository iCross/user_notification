require 'active_support'
require 'action_view'
# +user_notification+ keeps track of changes made to models
# and allows you to display them to the users.
#
# Check {UserNotification::Notifiable::ClassMethods#notifiable} for more details about customizing and specifying
# ownership to users.
module UserNotification
  extend ActiveSupport::Concern
  extend ActiveSupport::Autoload

  autoload :Notification,     'user_notification/models/notification'
  autoload :Activist,     'user_notification/models/activist'
  autoload :Adapter,      'user_notification/models/adapter'
  autoload :Notifiable,    'user_notification/models/notifiable'
  autoload :Common
  autoload :Config
  autoload :Creation,     'user_notification/actions/creation.rb'
  autoload :Deactivatable,'user_notification/roles/deactivatable.rb'
  autoload :Destruction,  'user_notification/actions/destruction.rb'
  autoload :Renderable
  autoload :ActsAsNotifiable,      'user_notification/roles/acts_as_notifiable.rb'
  autoload :Update,       'user_notification/actions/update.rb'
  autoload :VERSION

  # Switches UserNotification on or off.
  # @param value [Boolean]
  # @since 0.5.0
  def self.enabled=(value)
    UserNotification.config.enabled = value
  end

  # Returns `true` if UserNotification is on, `false` otherwise.
  # Enabled by default.
  # @return [Boolean]
  # @since 0.5.0
  def self.enabled?
    !!UserNotification.config.enabled
  end

  # Returns UserNotification's configuration object.
  # @since 0.5.0
  def self.config
    @@config ||= UserNotification::Config.instance
  end

  # Method used to choose which ORM to load
  # when UserNotification::Notification class is being autoloaded
  def self.inherit_orm(model="Notification")
    orm = UserNotification.config.orm
    require "user_notification/orm/#{orm.to_s}"
    "UserNotification::ORM::#{orm.to_s.classify}::#{model}".constantize
  end

  # Module to be included in ActiveRecord models. Adds required functionality.
  module Model
    extend ActiveSupport::Concern
    included do
      include Common
      include Deactivatable
      include ActsAsNotifiable
      include Activist  # optional associations by recipient|owner
    end
  end
end

require 'user_notification/utility/store_controller'
require 'user_notification/utility/view_helpers'
