require 'test_helper'

describe UserNotification::Common do
  before do
    @owner     = User.create(:name => "Peter Pan")
    @recipient = User.create(:name => "Bruce Wayne")
    @options   = {:params => {:author_name => "Peter",
                  :summary => "Default summary goes here..."},
                  :owner => @owner, :recipient => @recipient}
  end
  subject { article(@options).new }

  it 'prioritizes parameters passed to #create_notification' do
    subject.save
    subject.create_notification(:test, params: {author_name: 'Pan'}).parameters[:author_name].must_equal 'Pan'
    subject.create_notification(:test, parameters: {author_name: 'Pan'}).parameters[:author_name].must_equal 'Pan'
    subject.create_notification(:test, params: {author_name: nil}).parameters[:author_name].must_be_nil
    subject.create_notification(:test, parameters: {author_name: nil}).parameters[:author_name].must_be_nil
  end

  it 'prioritizes owner passed to #create_notification' do
    subject.save
    subject.create_notification(:test, owner: @recipient).owner.must_equal @recipient
    subject.create_notification(:test, owner: nil).owner.must_be_nil
  end

  it 'prioritizes recipient passed to #create_notification' do
    subject.save
    subject.create_notification(:test, recipient: @owner).recipient.must_equal @owner
    subject.create_notification(:test, recipient: nil).recipient.must_be_nil
  end

  it 'uses global fields' do
    subject.save
    notification = subject.notifications.last
    notification.parameters.must_equal @options[:params]
    notification.owner.must_equal @owner
  end

  it 'allows custom fields' do
    subject.save
    subject.create_notification :with_custom_fields, nonstandard: "Custom allowed"
    subject.notifications.last.nonstandard.must_equal "Custom allowed"
  end

  it '#create_notification returns a new notification object' do
    subject.save
    subject.create_notification("some.key").wont_be_nil
  end

  it 'allows passing owner through #create_notification' do
    article = article().new
    article.save
    notification = article.create_notification("some.key", :owner => @owner)
    notification.owner.must_equal @owner
  end

  it 'allows resolving custom fields' do
    subject.name      = "Resolving is great"
    subject.published = true
    subject.save
    subject.create_notification :with_custom_fields, nonstandard: :name
    subject.notifications.last.nonstandard.must_equal "Resolving is great"
    subject.create_notification :with_custom_fields_2, nonstandard: proc {|_, model| model.published.to_s}
    subject.notifications.last.nonstandard.must_equal "true"
  end

  it 'inherits instance parameters' do
    subject.notification :params => {:author_name => "Michael"}
    subject.save
    notification = subject.notifications.last

    notification.parameters[:author_name].must_equal "Michael"
  end

  it 'accepts instance recipient' do
    subject.notification :recipient => @recipient
    subject.save
    subject.notifications.last.recipient.must_equal @recipient
  end

  it 'accepts instance owner' do
    subject.notification :owner => @owner
    subject.save
    subject.notifications.last.owner.must_equal @owner
  end

  it 'accepts owner as a symbol' do
    klass = article(:owner => :user)
    @article = klass.new(:user => @owner)
    @article.save
    notification = @article.notifications.last

    notification.owner.must_equal @owner
  end

  describe '#extract_key' do
    describe 'for class#notification_key method' do
      before do
        @article = article(:owner => :user).new(:user => @owner)
      end

      it 'assigns key to value of notification_key if set' do
        def @article.notification_key; "my_custom_key" end

        @article.extract_key(:create, {}).must_equal "my_custom_key"
      end

      it 'assigns key based on class name as fallback' do
        def @article.notification_key; nil end

        @article.extract_key(:create).must_equal "article.create"
      end

      it 'assigns key value from options hash' do
        @article.extract_key(:create, :key => :my_custom_key).must_equal "my_custom_key"
      end
    end

    describe 'for camel cased classes' do
      before do
        class CamelCase < article(:owner => :user)
          def self.name; 'CamelCase' end
        end
        @camel_case = CamelCase.new
      end

      it 'assigns generates key from class name' do
        @camel_case.extract_key(:create, {}).must_equal "camel_case.create"
      end
    end

    describe 'for namespaced classes' do
      before do
        module ::MyNamespace;
          class CamelCase < article(:owner => :user)
            def self.name; 'MyNamespace::CamelCase' end
          end
        end
        @namespaced_camel_case = MyNamespace::CamelCase.new
      end

      it 'assigns key value from options hash' do
        @namespaced_camel_case.extract_key(:create, {}).must_equal "my_namespace_camel_case.create"
      end
    end
  end

  # no key implicated or given
  specify { ->{subject.prepare_settings}.must_raise UserNotification::NoKeyProvided }

  describe 'resolving values' do
    it 'allows procs with models and controllers' do
      context = mock('context')
      context.expects(:accessor).times(2).returns(5)
      controller = mock('controller')
      controller.expects(:current_user).returns(:cu)
      UserNotification.set_controller(controller)
      p = proc {|controller, model|
        assert_equal :cu, controller.current_user
        assert_equal 5, model.accessor
      }
      UserNotification.resolve_value(context, p)
      UserNotification.resolve_value(context, :accessor)
    end
  end

end
