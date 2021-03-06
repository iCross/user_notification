require 'test_helper'

describe UserNotification::Activist do
  it 'adds owner association' do
    klass = article
    klass.must_respond_to :acts_as_activist
    klass.acts_as_activist
    klass.new.must_respond_to :notifications
    klass.reflect_on_association(:notifications_as_owner).options[:as].must_equal :owner

    klass.reflect_on_association(:notifications_as_owner).options[:class_name].must_equal "Notification"
  end

  it 'returns notifications from association' do
    class ActivistUser < ActiveRecord::Base
      include UserNotification::Model
      self.table_name = 'users'
      acts_as_activist
    end

    owner = ActivistUser.create(:name => "Peter Pan")
    a = article(owner: owner).new
    a.save

    owner.notifications_as_owner.length.must_equal 1
  end
end
