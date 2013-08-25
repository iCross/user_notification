module UserNotification
  # Main module extending classes we want to keep track of.
  module Tracked
    extend ActiveSupport::Concern
    # A shortcut method for setting custom key, owner and parameters of {Notification}
    # in one line. Accepts a hash with 3 keys:
    # :key, :owner, :params. You can specify all of them or just the ones you want to overwrite.
    #
    # == Options
    #
    # [:key]
    #   See {Common#notification_key}
    # [:owner]
    #   See {Common#notification_owner}
    # [:params]
    #   See {Common#notification_params}
    # [:recipient]
    #   Set the recipient for this notification. Useful for private notifications, which should only be visible to a certain user. See {Common#notification_recipient}.
    # @example
    #
    #   @article = Article.new
    #   @article.title = "New article"
    #   @article.notification :key => "my.custom.article.key", :owner => @article.author, :params => {:title => @article.title}
    #   @article.save
    #   @article.notifications.last.key #=> "my.custom.article.key"
    #   @article.notifications.last.parameters #=> {:title => "New article"}
    #
    # @param options [Hash] instance options to set on the tracked model
    # @return [nil]
    def notification(options = {})
      rest = options.clone
      self.notification_key = rest.delete(:key) if rest[:key]
      self.notification_owner = rest.delete(:owner) if rest[:owner]
      self.notification_params = rest.delete(:params) if rest[:params]
      self.notification_recipient = rest.delete(:recipient) if rest[:recipient]
      self.notification_custom_fields = rest if rest.count > 0
      nil
    end

    # Module with basic +tracked+ method that enables tracking models.
    module ClassMethods
      # Adds required callbacks for creating and updating
      # tracked models and adds +notifications+ relation for listing
      # associated notifications.
      #
      # == Parameters:
      # [:owner]
      #   Specify the owner of the {Notification} (person responsible for the action).
      #   It can be a Proc, Symbol or an ActiveRecord object:
      #   == Examples:
      #
      #    tracked :owner => :author
      #    tracked :owner => proc {|o| o.author}
      #
      #   Keep in mind that owner relation is polymorphic, so you can't just
      #   provide id number of the owner object.
      # [:recipient]
      #   Specify the recipient of the {Notification}
      #   It can be a Proc, Symbol, or an ActiveRecord object
      #   == Examples:
      #
      #    tracked :recipient => :author
      #    tracked :recipient => proc {|o| o.author}
      #
      #   Keep in mind that recipient relation is polymorphic, so you can't just
      #   provide id number of the owner object.
      # [:params]
      #   Accepts a Hash with custom parameters you want to pass to i18n.translate
      #   method. It is later used in {Renderable#text} method.
      #   == Example:
      #    class Article < ActiveRecord::Base
      #      include UserNotification::Model
      #      tracked :params => {
      #          :title => :title,
      #          :author_name => "Michael",
      #          :category_name => proc {|controller, model_instance| model_instance.category.name},
      #          :summary => proc {|controller, model_instance| truncate(model.text, :length => 30)}
      #      }
      #    end
      #
      #   Values in the :params hash can either be an *exact* *value*, a *Proc/Lambda* executed before saving the notification or a *Symbol*
      #   which is a an attribute or a method name executed on the tracked model's instance.
      #
      #   Everything specified here has a lower priority than parameters
      #   specified directly in {#notification} method.
      #   So treat it as a place where you provide 'default' values or where you
      #   specify what data should be gathered for every notification.
      #   For more dynamic settings refer to {Notification} model documentation.
      # [:skip_defaults]
      #   Disables recording of notifications on create/update/destroy leaving that to programmer's choice. Check {UserNotification::Common#create_notification}
      #   for a guide on how to manually record notifications.
      # [:only]
      #   Accepts a symbol or an array of symbols, of which any combination of the three is accepted:
      #   * _:create_
      #   * _:update_
      #   * _:destroy_
      #   Selecting one or more of these will make UserNotification create notifications
      #   automatically for the tracked model on selected actions.
      #
      #   Resulting notifications will have have keys assigned to, respectively:
      #   * _article.create_
      #   * _article.update_
      #   * _article.destroy_
      #   Since only three options are valid,
      #   see _:except_ option for a shorter version
      # [:except]
      #   Accepts a symbol or an array of symbols with values like in _:only_, above.
      #   Values provided will be subtracted from all default actions:
      #   (create, update, destroy).
      #
      #   So, passing _create_ would track and automatically create
      #   notifications on _update_ and _destroy_ actions,
      #   but not on the _create_ action.
      # [:on]
      #   Accepts a Hash with key being the *action* on which to execute *value* (proc)
      #   Currently supported only for CRUD actions which are enabled in _:only_
      #   or _:except_ options on this method.
      #
      #   Key-value pairs in this option define callbacks that can decide
      #   whether to create an notification or not. Procs have two attributes for
      #   use: _model_ and _controller_. If the proc returns true, the notification
      #   will be created, if not, then notification will not be saved.
      #
      #   == Example:
      #     # app/models/article.rb
      #     tracked :on => {:update => proc {|model, controller| model.published? }}
      #
      #   In the example above, given a model Article with boolean column _published_.
      #   The notifications with key _article.update_ will only be created
      #   if the published status is set to true on that article.
      # @param opts [Hash] options
      # @return [nil] options
      def tracked(opts = {})
        options = opts.clone

        all_options = [:create, :update, :destroy]

        if !options.has_key?(:skip_defaults) && !options[:only] && !options[:except]
          include Creation
          include Destruction
          include Update
        end
        options.delete(:skip_defaults)

        if options[:except]
          options[:only] = all_options - Array(options.delete(:except))
        end

        if options[:only]
          Array(options[:only]).each do |opt|
            if opt.eql?(:create)
              include Creation
            elsif opt.eql?(:destroy)
              include Destruction
            elsif opt.eql?(:update)
              include Update
            end
          end
          options.delete(:only)
        end

        if options[:owner]
          self.notification_owner_global = options.delete(:owner)
        end
        if options[:recipient]
          self.notification_recipient_global = options.delete(:recipient)
        end
        if options[:params]
          self.notification_params_global = options.delete(:params)
        end
        if options.has_key?(:on) and options[:on].is_a? Hash
          self.notification_hooks = options.delete(:on).select {|_, v| v.is_a? Proc}.symbolize_keys
        end

        options.each do |k, v|
          self.notification_custom_fields_global[k] = v
        end

        nil
      end
    end
  end
end
