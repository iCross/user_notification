require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

unless ENV['NOCOV']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
  end
end
$:.unshift File.expand_path('../../lib/', __FILE__)
require 'active_support/testing/setup_and_teardown'
require 'user_notification'
require 'minitest/autorun'
require 'minitest/pride' if ENV['WITH_PRIDE'] or ENV['PRIDE']

UserNotification::Config.orm = (ENV['PA_ORM'] || :active_record)

case UserNotification::Config.orm
when :active_record
  require 'active_record'
  require 'active_record/connection_adapters/sqlite3_adapter'
  require 'stringio'        # silence the output
  $stdout = StringIO.new    # from migrator
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
  ActiveRecord::Migrator.migrate(File.expand_path('../migrations', __FILE__))
  $stdout = STDOUT

  def article(options = {})
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'articles'
      include UserNotification::Model
      acts_as_notifiable options
      belongs_to :user

      def self.name
        "Article"
      end

      if ::ActiveRecord::VERSION::MAJOR < 4
        attr_accessible :name, :published, :user
      end
    end
    klass
  end
  class User < ActiveRecord::Base; end

  if ::ActiveRecord::VERSION::MAJOR < 4
    UserNotification::Notification.class_eval do
      attr_accessible :nonstandard
    end
  end
when :mongoid
  require 'mongoid'

  Mongoid.load!(File.expand_path("test/mongoid.yml"), :test)

  class User
    include Mongoid::Document
    include Mongoid::Timestamps

    has_many :articles

    field :name, type: String
  end

  class Article
    include Mongoid::Document
    include Mongoid::Timestamps
    include UserNotification::Model

    belongs_to :user

    field :name, type: String
    field :published, type: Boolean
  end

  def article(options = {})
    Article.class_eval do
      set_user_notification_class_defaults
      acts_as_notifiable options
    end
    Article
  end

when :mongo_mapper
  require 'mongo_mapper'

  config = YAML.load(File.read("test/mongo_mapper.yml"))
  MongoMapper.setup(config, :test)

  class User
    include MongoMapper::Document

    has_many :articles

    key :name, String
    timestamps!
  end

  class Article
    include MongoMapper::Document
    include UserNotification::Model

    belongs_to :user

    key :name, String
    key :published, Boolean
  end

  def article(options = {})
    Article.class_eval do
      set_user_notification_class_defaults
      acts_as_notifiable options
    end
    Article
  end
end

class ViewSpec < MiniTest::Spec
  include ActiveSupport::Testing::SetupAndTeardown
  include ActionView::TestCase::Behavior
end
MiniTest::Spec.register_spec_type(/Rendering$/, ViewSpec)
