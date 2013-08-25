# Provides a shortcut from views to the rendering method.
module UserNotification
  # Module extending ActionView::Base and adding `render_notification` helper.
  module ViewHelpers
    # View helper for rendering an notification, calls {UserNotification::Notification#render} internally.
    def render_notification notifications, options = {}
      if notifications.is_a? UserNotification::Notification
        notifications.render self, options
      elsif notifications.respond_to?(:map)
        # depend on ORMs to fetch as needed
        # maybe we can support Postgres streaming with this?
        notifications.map {|notification| notification.render self, options.dup }.join.html_safe
      end
    end
    alias_method :render_notifications, :render_notification

    # Helper for setting content_for in notification partial, needed to
    # flush remains in between partial renders.
    def single_content_for(name, content = nil, &block)
      @view_flow.set(name, ActiveSupport::SafeBuffer.new)
      content_for(name, content, &block)
    end
  end

  ActionView::Base.class_eval { include ViewHelpers }
end
