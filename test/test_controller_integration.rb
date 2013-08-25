require 'test_helper'

class StoringController < ActionView::TestCase::TestController
  include UserNotification::StoreController
  include ActionController::Testing::ClassMethods
end

describe UserNotification::StoreController do
  it 'stores controller' do
    controller = StoringController.new
    UserNotification.set_controller(controller)
    controller.must_be_same_as UserNotification.instance_eval { class_variable_get(:@@controllers)[Thread.current.object_id] }
    controller.must_be_same_as UserNotification.get_controller
  end

  it 'stores controller with a filter in controller' do
    controller = StoringController.new
    controller._process_action_callbacks.select {|c| c.kind == :before}.map(&:filter).must_include :store_controller_for_user_notification
    controller.instance_eval { store_controller_for_user_notification }
    controller.must_be_same_as UserNotification.class_eval { class_variable_get(:@@controllers)[Thread.current.object_id] }
  end

  it 'stores controller in a threadsafe way' do
    reset_controllers
    UserNotification.set_controller(1)
    UserNotification.get_controller.must_equal 1

    a = Thread.new {
      UserNotification.set_controller(2)
      UserNotification.get_controller.must_equal 2
    }

    UserNotification.get_controller.must_equal 1
    # cant really test finalizers though
  end

  private
  def reset_controllers
    UserNotification.class_eval { class_variable_set(:@@controllers, {}) }
  end
end
