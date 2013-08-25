module UserNotification
  # Provides logic for rendering notifications. Handles both i18n strings
  # support and smart partials rendering (different templates per notification key).
  module Renderable
    # Virtual attribute returning text description of the notification
    # using the notification's key to translate using i18n.
    def text(params = {})
      # TODO: some helper for key transformation for two supported formats
      k = key.split('.')
      k.unshift('notification') if k.first != 'notification'
      k = k.join('.')

      I18n.t(k, parameters.merge(params) || {})
    end

    # Renders notification from views.
    #
    # @param [ActionView::Base] context
    # @return [nil] nil
    #
    # Renders notification to the given ActionView context with included
    # AV::Helpers::RenderingHelper (most commonly just ActionView::Base)
    #
    # The *preferred* *way* of rendering notifications is
    # to provide a template specifying how the rendering should be happening.
    # However, one may choose using _I18n_ based approach when developing
    # an application that supports plenty of languages.
    #
    # If partial view exists that matches the *key* attribute
    # renders that partial with local variables set to contain both
    # Notification and notification_parameters (hash with indifferent access)
    #
    # Otherwise, it outputs the I18n translation to the context
    # @example Render a list of all notifications from a view (erb)
    #   <ul>
    #     <% for notification in UserNotification::Notification.all %>
    #      <li><%= render_notification(notification) %></li>
    #     <% end %>
    #   </ul>
    #
    # = Layouts
    # You can supply a layout that will be used for notification partials
    # with :layout param.
    # Keep in mind that layouts for partials are also partials.
    # @example Supply a layout
    #   # in views:
    #   #   All examples look for a layout in app/views/layouts/_notification.erb
    #    render_notification @notification, :layout => "notification"
    #    render_notification @notification, :layout => "layouts/notification"
    #    render_notification @notification, :layout => :notification
    #
    #   # app/views/layouts/_notification.erb
    #   <p><%= a.created_at %></p>
    #   <%= yield %>
    #
    # = Creating a template
    # To use templates for formatting how the notification should render,
    # create a template based on notification key, for example:
    #
    # Given a key _notification.article.create_, create directory tree
    # _app/views/user_notification/article/_ and create the _create_ partial there
    #
    # Note that if a key consists of more than three parts splitted by commas, your
    # directory structure will have to be deeper, for example:
    #   notification.article.comments.destroy => app/views/user_notification/articles/comments/_destroy.html.erb
    #
    # == Variables in templates
    # From within a template there are two variables at your disposal:
    # * notification (aliased as *a* for a shortcut)
    # * params   (aliased as *p*) [converted into a HashWithIndifferentAccess]
    #
    # @example Template for key: _notification.article.create_ (erb)
    #   <p>
    #     Article <strong><%= p[:name] %></strong>
    #     was written by <em><%= p["author"] %></em>
    #     <%= distance_of_time_in_words_to_now(a.created_at) %>
    #   </p>
    def render(context, params = {})
      partial_path = nil
      if params.has_key? :display
        # if i18n has been requested, let it render and bail
        return context.render :text => self.text(params) if params[:display].to_sym == :"i18n"
        partial_path = 'user_notification/'+params[:display].to_s
      end

      controller = UserNotification.get_controller
      if layout = params.delete(:layout)
        layout = layout.to_s
        layout = layout[0,8] == "layouts/" ? layout : "layouts/#{layout}"
      end

      locals = params.delete(:locals) || Hash.new

      params_indifferent = self.parameters.with_indifferent_access
      params_indifferent.merge!(params)

      context.render :partial => (partial_path || self.template_path(self.key)),
        :layout => layout,
        :locals => locals.merge(:a => self, :notification => self,
           :controller => controller,
           :current_user => controller.respond_to?(:current_user) ?
                controller.current_user : nil ,
           :p => params_indifferent, :params => params_indifferent)
    end

    protected
    # Builds the path to template based on notification key
    # TODO: verify that attribute `key` is splitted by commas
    #       and that the word before first comma is equal to
    #       "notification"
    def template_path(key)
      path = key.split(".")
      path.delete_at(0) if path[0] == "notification"
      path.unshift "user_notification"
      path.join("/")
    end
  end
end
