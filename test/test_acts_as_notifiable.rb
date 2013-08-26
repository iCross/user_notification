require 'test_helper'

describe UserNotification::ActsAsNotifiable do
  describe 'defining instance options' do
    subject { article.new }
    let :options do
      { :key => 'key',
        :params => {:a => 1},
        :owner => User.create,
        :recipients => [ User.create ] }
    end
    before(:each) { subject.notification(options) }
    let(:notification){ subject.save; subject.notifications.last }

    specify { subject.notification_key.must_be_same_as    options[:key] }
    specify { notification.key.must_equal                 options[:key] }

    specify { subject.notification_owner.must_be_same_as  options[:owner] }
    specify { notification.owner.must_equal               options[:owner] }

    specify { subject.notification_params.must_be_same_as options[:params] }
    specify { notification.parameters.must_equal          options[:params] }

    specify { subject.notification_recipients.must_be_same_as options[:recipients] }
    specify { notification.recipients.must_equal              options[:recipients] }
  end

  it 'can be acts_as_notifiable and be an activist at the same time' do
    case UserNotification.config.orm
      when :mongoid
        class ActivistAndNotifiableArticle
          include Mongoid::Document
          include Mongoid::Timestamps
          include UserNotification::Model

          belongs_to :user

          field :name, type: String
          field :published, type: Boolean
          acts_as_notifiable
          acts_as_activist
        end
      when :mongo_mapper
        class ActivistAndNotifiableArticle
          include MongoMapper::Document
          include UserNotification::Model

          belongs_to :user

          key :name, String
          key :published, Boolean
          acts_as_notifiable
          acts_as_activist
          timestamps!
        end
      when :active_record
        class ActivistAndNotifiableArticle < ActiveRecord::Base
          self.table_name = 'articles'
          include UserNotification::Model
          acts_as_notifiable
          acts_as_activist

          if ::ActiveRecord::VERSION::MAJOR < 4
            attr_accessible :name, :published, :user
          end
          belongs_to :user
        end
    end

    art = ActivistAndNotifiableArticle.new
    art.save
    art.notifications.last.notifiable_id.must_equal art.id
    art.notifications.last.owner_id.must_equal nil
  end

  describe 'custom fields' do
    describe 'global' do
      it 'should resolve symbols' do
        a = article(nonstandard: :name).new(name: 'Symbol resolved')
        a.save
        a.notifications.last.nonstandard.must_equal 'Symbol resolved'
      end

      it 'should resolve procs' do
        a = article(nonstandard: proc {|_, model| model.name}).new(name: 'Proc resolved')
        a.save
        a.notifications.last.nonstandard.must_equal 'Proc resolved'
      end
    end

    describe 'instance' do
      it 'should resolve symbols' do
        a = article.new(name: 'Symbol resolved')
        a.notification nonstandard: :name
        a.save
        a.notifications.last.nonstandard.must_equal 'Symbol resolved'
      end

      it 'should resolve procs' do
        a = article.new(name: 'Proc resolved')
        a.notification nonstandard: proc {|_, model| model.name}
        a.save
        a.notifications.last.nonstandard.must_equal 'Proc resolved'
      end
    end
  end

  it 'should reset instance options on successful create_notification' do
    a = article.new
    a.notification key: 'test', params: {test: 1}
    a.save
    a.notifications.count.must_equal 1
    ->{a.create_notification}.must_raise UserNotification::NoKeyProvided
    a.notification_params.must_be_empty
    a.notification key: 'asd'
    a.create_notification
    ->{a.create_notification}.must_raise UserNotification::NoKeyProvided
  end

  it 'should not accept global key option' do
    # this example tests the lack of presence of sth that should not be here
    a = article(key: 'asd').new
    a.save
    ->{a.create_notification}.must_raise UserNotification::NoKeyProvided
    a.notifications.count.must_equal 1
  end

  it 'should not change global custom fields' do
    a = article(nonstandard: 'global').new
    a.notification nonstandard: 'instance'
    a.save
    a.class.notification_custom_fields_global.must_equal nonstandard: 'global'
  end

  describe 'disabling functionality' do
    it 'allows for global disable' do
      UserNotification.enabled = false
      notification_count_before = UserNotification::Notification.count

      @article = article().new
      @article.save
      UserNotification::Notification.count.must_equal notification_count_before

      UserNotification.enabled = true
    end

    it 'allows for class-wide disable' do
      notification_count_before = UserNotification::Notification.count

      klass = article
      klass.user_notification_off
      @article = klass.new
      @article.save
      UserNotification::Notification.count.must_equal notification_count_before

      klass.user_notification_on
      @article.save
      UserNotification::Notification.count.must_be :>, notification_count_before
    end
  end

  describe '#acts_as_notifiable' do
    subject { article(options) }
    let(:options) { {} }

    it 'allows skipping the tracking on CRUD actions' do
      case UserNotification.config.orm
        when :mongoid
          art = Class.new do
            include Mongoid::Document
            include Mongoid::Timestamps
            include UserNotification::Model

            belongs_to :user

            field :name, type: String
            field :published, type: Boolean
            acts_as_notifiable :skip_defaults => true
          end
        when :mongo_mapper
          art = Class.new do
            include MongoMapper::Document
            include UserNotification::Model

            belongs_to :user

            key :name, String
            key :published, Boolean
            acts_as_notifiable :skip_defaults => true

            timestamps!
          end
        when :active_record
          art = article(:skip_defaults => true)
      end

      art.must_include UserNotification::Common
      art.wont_include UserNotification::Creation
      art.wont_include UserNotification::Update
      art.wont_include UserNotification::Destruction
    end

    describe 'default options' do
      subject { article }

      specify { subject.must_include UserNotification::Creation }
      specify { subject.must_include UserNotification::Destruction }
      specify { subject.must_include UserNotification::Update }

      specify { subject._create_callbacks.select do |c|
        c.kind.eql?(:after) && c.filter == :notification_on_create
      end.wont_be_empty }

      specify { subject._update_callbacks.select do |c|
        c.kind.eql?(:after) && c.filter == :notification_on_update
      end.wont_be_empty }

      specify { subject._destroy_callbacks.select do |c|
        c.kind.eql?(:before) && c.filter == :notification_on_destroy
      end.wont_be_empty }
    end

    it 'accepts :except option' do
      case UserNotification.config.orm
        when :mongoid
          art = Class.new do
            include Mongoid::Document
            include Mongoid::Timestamps
            include UserNotification::Model

            belongs_to :user

            field :name, type: String
            field :published, type: Boolean
            acts_as_notifiable :except => [:create]
          end
        when :mongo_mapper
          art = Class.new do
            include MongoMapper::Document
            include UserNotification::Model

            belongs_to :user

            key :name, String
            key :published, Boolean
            acts_as_notifiable :except => [:create]

            timestamps!
          end
        when :active_record
          art = article(:except => [:create])
      end

      art.wont_include UserNotification::Creation
      art.must_include UserNotification::Update
      art.must_include UserNotification::Destruction
    end

    it 'accepts :only option' do
      case UserNotification.config.orm
        when :mongoid
          art = Class.new do
            include Mongoid::Document
            include Mongoid::Timestamps
            include UserNotification::Model

            belongs_to :user

            field :name, type: String
            field :published, type: Boolean

            acts_as_notifiable :only => [:create, :update]
          end
        when :mongo_mapper
          art = Class.new do
            include MongoMapper::Document
            include UserNotification::Model

            belongs_to :user

            key :name, String
            key :published, Boolean

            acts_as_notifiable :only => [:create, :update]
          end
        when :active_record
          art = article({:only => [:create, :update]})
      end

      art.must_include UserNotification::Creation
      art.wont_include UserNotification::Destruction
      art.must_include UserNotification::Update
    end

    it 'accepts :owner option' do
      owner = mock('owner')
      subject.acts_as_notifiable(:owner => owner)
      subject.notification_owner_global.must_equal owner
    end

    it 'accepts :params option' do
      params = {:a => 1}
      subject.acts_as_notifiable(:params => params)
      subject.notification_params_global.must_equal params
    end

    it 'accepts :on option' do
      on = {:a => lambda{}, :b => proc {}}
      subject.acts_as_notifiable(:on => on)
      subject.notification_hooks.must_equal on
    end

    it 'accepts :on option with string keys' do
      on = {'a' => lambda {}}
      subject.acts_as_notifiable(:on => on)
      subject.notification_hooks.must_equal on.symbolize_keys
    end

    it 'accepts :on values that are procs' do
      on = {:unpassable => 1, :proper => lambda {}, :proper_proc => proc {}}
      subject.acts_as_notifiable(:on => on)
      subject.notification_hooks.must_include :proper
      subject.notification_hooks.must_include :proper_proc
      subject.notification_hooks.wont_include :unpassable
    end

    describe 'global options' do
      subject { article(recipients: [:test], owner: :test2, params: {a: 'b'}) }

      specify { subject.notification_recipients_global.must_equal [:test] }
      specify { subject.notification_owner_global.must_equal :test2    }
      specify { subject.notification_params_global.must_equal(a: 'b')  }
    end
  end

  describe 'notification hooks' do
    subject { s = article; s.notification_hooks = {:test => hook}; s }
    let(:hook) { lambda {} }

    it 'retrieves hooks' do
      assert_same hook, subject.get_hook(:test)
    end

    it 'retrieves hooks by string keys' do
      assert_same hook, subject.get_hook('test')
    end

    it 'returns nil when no matching hook is present' do
      nil.must_be_same_as subject.get_hook(:nonexistent)
    end

    it 'allows hooks to decide if notification should be created' do
      subject.acts_as_notifiable
      @article = subject.new(:name => 'Some Name')
      UserNotification.set_controller(mock('controller'))
      pf = proc { |model, controller|
        controller.must_be_same_as UserNotification.get_controller
        model.name.must_equal 'Some Name'
        false
      }
      pt = proc { |model, controller|
        controller.must_be_same_as UserNotification.get_controller
        model.name.must_equal 'Other Name'
        true # this will save the notification with *.update key
      }
      @article.class.notification_hooks = {:create => pf, :update => pt, :destroy => pt}

      @article.notifications.to_a.must_be_empty
      @article.save # create
      @article.name = 'Other Name'
      @article.save # update
      @article.destroy # destroy

      @article.notifications.count.must_equal 2
      @article.notifications.first.key.must_equal 'article.update'
    end
  end
end
