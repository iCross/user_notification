require 'test_helper'

describe 'ViewHelpers Rendering' do
  include UserNotification::ViewHelpers

  # is this a proper test?
  it 'provides render_notification helper' do
    notification = mock('notification')
    notification.stubs(:is_a?).with(UserNotification::Notification).returns(true)
    notification.expects(:render).with(self, {})
    render_notification(notification)
  end

  it 'handles multiple notifications' do
    notification = mock('notification')
    notification.expects(:render).with(self, {})
    render_notifications([notification])
  end

  it 'flushes content_for between partials renderes' do
    @view_flow = mock('view_flow')
    @view_flow.expects(:set).twice.with('name', ActiveSupport::SafeBuffer.new)

    single_content_for('name', 'content')
    @name.must_equal 'name'
    @content.must_equal 'content'
    single_content_for('name', 'content2')
    @name.must_equal 'name'
    @content.must_equal 'content2'
  end

  def content_for(name, content, &block)
    @name = name
    @content = content
  end
end
