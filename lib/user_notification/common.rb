module UserNotification
  # Happens when creating custom notifications without either action or a key.
  class NoKeyProvided < Exception; end

  # Used to smartly transform value from metadata to data.
  # Accepts Symbols, which it will send against context.
  # Accepts Procs, which it will execute with controller and context.
  # @since 0.4.0
  def self.resolve_value(context, thing)
    case thing
    when Symbol
      context.__send__(thing)
    when Proc
      thing.call(UserNotification.get_controller, context)
    else
      thing
    end
  end

  # Common methods shared across the gem.
  module Common
    extend ActiveSupport::Concern

    included do
      include Trackable
      class_attribute :notification_owner_global, :notification_recipient_global,
                      :notification_params_global, :notification_hooks, :notification_custom_fields_global
      set_user_notification_class_defaults
    end

    # @!group Global options

    # @!attribute notification_owner_global
    #   Global version of notification owner
    #   @see #notification_owner
    #   @return [Model]

    # @!attribute notification_recipient_global
    #   Global version of notification recipient
    #   @see #notification_recipient
    #   @return [Model]

    # @!attribute notification_params_global
    #   Global version of notification parameters
    #   @see #notification_params
    #   @return [Hash<Symbol, Object>]

    # @!attribute notification_hooks
    #   @return [Hash<Symbol, Proc>]
    #   Hooks/functions that will be used to decide *if* the notification should get
    #   created.
    #
    #   The supported keys are:
    #   * :create
    #   * :update
    #   * :destroy

    # @!endgroup

    # @!group Instance options

    # Set or get parameters that will be passed to {Notification} when saving
    #
    # == Usage:
    #
    #   @article.notification_params = {:article_title => @article.title}
    #   @article.save
    #
    # This way you can pass strings that should remain constant, even when model attributes
    # change after creating this {Notification}.
    # @return [Hash<Symbol, Object>]
    attr_accessor :notification_params
    @notification_params = {}
    # Set or get owner object responsible for the {Notification}.
    #
    # == Usage:
    #
    #   # where current_user is an object of logged in user
    #   @article.notification_owner = current_user
    #   # OR: take @article.author association
    #   @article.notification_owner = :author
    #   # OR: provide a Proc with custom code
    #   @article.notification_owner = proc {|controller, model| model.author }
    #   @article.save
    #   @article.notifications.last.owner #=> Returns owner object
    # @return [Model] Polymorphic model
    # @see #notification_owner_global
    attr_accessor :notification_owner
    @notification_owner = nil

    # Set or get recipient for notification.
    #
    # Association is polymorphic, thus allowing assignment of
    # all types of models. This can be used for example in the case of sending
    # private notifications for only a single user.
    # @return (see #notification_owner)
    attr_accessor :notification_recipient
    @notification_recipient = nil
    # Set or get custom i18n key passed to {Notification}, later used in {Renderable#text}
    #
    # == Usage:
    #
    #   @article = Article.new
    #   @article.notification_key = "my.custom.article.key"
    #   @article.save
    #   @article.notifications.last.key #=> "my.custom.article.key"
    #
    # @return [String]
    attr_accessor :notification_key
    @notification_key = nil

    # Set or get custom fields for later processing
    #
    # @return [Hash]
    attr_accessor :notification_custom_fields
    @notification_custom_fields = {}

    # @!visibility private
    @@notification_hooks = {}

    # @!endgroup

    # Provides some global methods for every model class.
    module ClassMethods
      #
      # @since 1.0.0
      # @api private
      def set_user_notification_class_defaults
        self.notification_owner_global             = nil
        self.notification_recipient_global         = nil
        self.notification_params_global            = {}
        self.notification_hooks                    = {}
        self.notification_custom_fields_global     = {}
      end

      # Extracts a hook from the _:on_ option provided in
      # {Tracked::ClassMethods#tracked}. Returns nil when no hook exists for
      # given action
      # {Common#get_hook}
      #
      # @see Tracked#get_hook
      # @param key [String, Symbol] action to retrieve a hook for
      # @return [Proc, nil] callable hook or nil
      # @since 0.4.0
      # @api private
      def get_hook(key)
        key = key.to_sym
        if self.notification_hooks.has_key?(key) and self.notification_hooks[key].is_a? Proc
          self.notification_hooks[key]
        else
          nil
        end
      end
    end
    #
    # Returns true if UserNotification is enabled
    # globally and for this class.
    # @return [Boolean]
    # @api private
    # @since 0.5.0
    def user_notification_enabled?
      UserNotification.enabled?
    end
    #
    # Shortcut for {ClassMethods#get_hook}
    # @param (see ClassMethods#get_hook)
    # @return (see ClassMethods#get_hook)
    # @since (see ClassMethods#get_hook)
    # @api (see ClassMethods#get_hook)
    def get_hook(key)
      self.class.get_hook(key)
    end

    # Calls hook safely.
    # If a hook for given action exists, calls it with model (self) and
    # controller (if available, see {StoreController})
    # @param key (see #get_hook)
    # @return [Boolean] if hook exists, it's decision, if there's no hook, true
    # @since 0.4.0
    # @api private
    def call_hook_safe(key)
      hook = self.get_hook(key)
      if hook
        # provides hook with model and controller
        hook.call(self, UserNotification.get_controller)
      else
        true
      end
    end

    # Directly creates notification record in the database, based on supplied options.
    #
    # It's meant for creating custom notifications while *preserving* *all*
    # *configuration* defined before. If you fire up the simplest of options:
    #
    #   current_user.create_notification(:avatar_changed)
    #
    # It will still gather data from any procs or symbols you passed as params
    # to {Tracked::ClassMethods#tracked}. It will ask the hooks you defined
    # whether to really save this notification.
    #
    # But you can also overwrite instance and global settings with your options:
    #
    #   @article.notification :owner => proc {|controller| controller.current_user }
    #   @article.create_notification(:commented_on, :owner => @user)
    #
    # And it's smart! It won't execute your proc, since you've chosen to
    # overwrite instance parameter _:owner_ with @user.
    #
    # [:key]
    #   The key will be generated from either:
    #   * the first parameter you pass that is not a hash (*action*)
    #   * the _:action_ option in the options hash (*action*)
    #   * the _:key_ option in the options hash (it has to be a full key,
    #     including model name)
    #   When you pass an *action* (first two options above), they will be
    #   added to parameterized model name:
    #
    #   Given Article model and instance: @article,
    #
    #     @article.create_notification :commented_on
    #     @article.notifications.last.key # => "article.commented_on"
    #
    # For other parameters, see {Tracked#notification}, and "Instance options"
    # accessors at {Tracked}, information on hooks is available at
    # {Tracked::ClassMethods#tracked}.
    # @see #prepare_settings
    # @return [Model, nil] If created successfully, new notification
    # @since 0.4.0
    # @api public
    # @overload create_notification(action, options = {})
    #   @param [Symbol,String] action Name of the action
    #   @param [Hash] options Options with quality higher than instance options
    #     set in {Tracked#notification}
    #   @option options [Activist] :owner Owner
    #   @option options [Activist] :recipient Recipient
    #   @option options [Hash] :params Parameters, see
    #     {UserNotification.resolve_value}
    # @overload create_notification(options = {})
    #   @param [Hash] options Options with quality higher than instance options
    #     set in {Tracked#notification}
    #   @option options [Symbol,String] :action Name of the action
    #   @option options [String] :key Full key
    #   @option options [Activist] :owner Owner
    #   @option options [Activist] :recipient Recipient
    #   @option options [Hash] :params Parameters, see
    #     {UserNotification.resolve_value}
    def create_notification(*args)
      return unless self.user_notification_enabled?
      options = prepare_settings(*args)

      if call_hook_safe(options[:key].split('.').last)
        reset_notification_instance_options
        return UserNotification::Adapter.create_notification(self, options)
      end

      nil
    end

    # Prepares settings used during creation of Notification record.
    # params passed directly to tracked model have priority over
    # settings specified in tracked() method
    #
    # @see #create_notification
    # @return [Hash] Settings with preserved options that were passed
    # @api private
    # @overload prepare_settings(action, options = {})
    #   @see #create_notification
    # @overload prepare_settings(options = {})
    #   @see #create_notification
    def prepare_settings(*args)
      # key
      all_options = args.extract_options!
      options = {
        key: all_options.delete(:key),
        action: all_options.delete(:action),
        parameters: all_options.delete(:parameters) || all_options.delete(:params)
      }
      action = (args.first || options[:action]).try(:to_s)

      options[:key] = extract_key(action, options)

      raise NoKeyProvided, "No key provided for #{self.class.name}" unless options[:key]

      options.delete(:action)

      # user responsible for the notification
      options[:owner] = UserNotification.resolve_value(self,
        (all_options.has_key?(:owner) ? all_options[:owner] : (
          self.notification_owner || self.class.notification_owner_global
          )
        )
      )

      # recipient of the notification
      options[:recipient] = UserNotification.resolve_value(self,
        (all_options.has_key?(:recipient) ? all_options[:recipient] : (
          self.notification_recipient || self.class.notification_recipient_global
          )
        )
      )

      #customizable parameters
      params = {}
      params.merge!(self.class.notification_params_global)
      params.merge!(self.notification_params) if self.notification_params
      params.merge!(options[:params] || options[:parameters] || {})
      params.each { |k, v| params[k] = UserNotification.resolve_value(self, v) }
      options[:parameters] = params
      options.delete(:params)

      customs = self.class.notification_custom_fields_global.clone
      customs.merge!(self.notification_custom_fields) if self.notification_custom_fields
      customs.merge!(all_options)
      customs.each do  |k, v|
        customs[k] = UserNotification.resolve_value(self, v)
      end.merge options
    end

    # Helper method to serialize class name into relevant key
    # @return [String] the resulted key
    # @param [Symbol] or [String] the name of the operation to be done on class
    # @param [Hash] options to be used on key generation, defaults to {}
    def extract_key(action, options = {})
      (options[:key] || self.notification_key ||
        ((self.class.name.underscore.gsub('/', '_') + "." + action.to_s) if action)
      ).try(:to_s)
    end

    # Resets all instance options on the object
    # triggered by a successful #create_notification, should not be
    # called from any other place, or from application code.
    # @private
    def reset_notification_instance_options
      @notification_params = {}
      @notification_key = nil
      @notification_owner = nil
      @notification_recipient = nil
      @notification_custom_fields = {}
    end
  end
end
