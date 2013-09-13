$:.push File.expand_path('../lib', __FILE__)
require 'user_notification/version'

Gem::Specification.new do |s|
  s.name = 'user_notification'
  s.version = UserNotification::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Wei Zhu", "Piotrek Okoński", "Kuba Okoński"]
  s.email = "yesmeck@gmail.com"
  s.homepage = 'https://github.com/yesmeck/user_notification'
  s.summary = "Easy user notification for your Rails application"
  s.description = "Easy user notification for your Rails application. Provides Notifiable model with details about actions performed by your users, like adding comments, responding etc."

  s.files = `git ls-files lib`.split("\n") + ['Gemfile','Rakefile','README.md', 'MIT-LICENSE']
  s.test_files = `git ls-files test`.split("\n")
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.2'

  if File.exists?('UPGRADING')
    s.post_install_message = File.read("UPGRADING")
  end

  s.add_dependency 'actionpack', '>= 4.0.0'
  s.add_dependency 'railties', '>= 4.0.0'
  s.add_dependency 'i18n', '>= 0.6.5'
  s.add_dependency 'activerecord', '>= 4.0'

  s.add_development_dependency 'sqlite3', '~> 1.3.7'
  s.add_development_dependency 'mocha', '~> 0.13.0'
  s.add_development_dependency 'simplecov', '~> 0.7.0'
  s.add_development_dependency 'minitest', '< 5.0.0'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'yard', '~> 0.8'
  s.add_development_dependency 'pry-nav'
end
