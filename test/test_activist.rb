require 'test_helper'

describe UserNotification::Activist do
  it 'adds owner association' do
    klass = article
    klass.must_respond_to :activist
    klass.activist
    klass.new.must_respond_to :notifications
    case ENV["PA_ORM"]
      when "active_record"
        klass.reflect_on_association(:notifications_as_owner).options[:as].must_equal :owner
      when "mongoid"
        klass.reflect_on_association(:notifications_as_owner).options[:inverse_of].must_equal :owner
      when "mongo_mapper"
        klass.associations[:notifications_as_owner].options[:as].must_equal :owner
    end

    if ENV["PA_ORM"] == "mongo_mapper"
      klass.associations[:notifications_as_owner].options[:class_name].must_equal "::UserNotification::Notification"
    else
      klass.reflect_on_association(:notifications_as_owner).options[:class_name].must_equal "::UserNotification::Notification"
    end
  end

  it 'returns notifications from association' do
    case UserNotification::Config.orm
      when :active_record
        class ActivistUser < ActiveRecord::Base
          include UserNotification::Model
          self.table_name = 'users'
          activist
        end
      when :mongoid
        class ActivistUser
          include Mongoid::Document
          include UserNotification::Model
          activist

          field :name, type: String
        end
      when :mongo_mapper
        class ActivistUser
          include MongoMapper::Document
          include UserNotification::Model
          activist

          key :name, String
        end
    end
    owner = ActivistUser.create(:name => "Peter Pan")
    a = article(owner: owner).new
    a.save

    owner.notifications_as_owner.length.must_equal 1
  end
end
