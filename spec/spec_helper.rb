# -*- coding: utf-8 -*-
require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'capybara/dsl'
  require 'capybara/rspec'
  require 'capybara/poltergeist'
  require 'turnip'
  require 'turnip/capybara'
  require 'simplecov' if ENV['COVERAGE'] || ENV['COVERALLS']

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  require_relative 'steps/global_variable'
  Dir.glob("spec/steps/**/*_steps.rb") { |f| load f, true }

  # Checks for pending migrations before tests are run.
  # If you are not using ActiveRecord, you can remove this line.
  ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

  RSpec.configure do |config|
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    # Run specs in random order to surface order dependencies. If you find an
    # order dependency and want to debug it, you can fix the order by providing
    # the seed, which is printed after each run.
    #     --seed 1234
    config.order = "random"


    case (ENV['TARGET_WEB_BROWZER'] || ENV['TWB']).try(:downcase)
    when 'firefox'
      Capybara.javascript_driver = :selenium
    when 'ie'
      Capybara.register_driver :selenium_ie do |app|
        Capybara::Selenium::Driver.new(app, browser: :ie, introduce_flakiness_by_ignoring_security_domains: true)
      end
      Capybara.javascript_driver = :selenium_ie
    when 'chrome'
      Capybara.register_driver :selenium_chrome do |app|
        Capybara::Selenium::Driver.new(app, browser: :chrome)
      end
      Capybara.javascript_driver = :selenium_chrome
    else
      Capybara.javascript_driver = :poltergeist
    end

    config.include JsonSpec::Helpers
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

  # http://penguinlab.jp/blog/post/2256# より
  if Spork.using_spork?
    # app 下のファイル / locale / routes をリロード
    # railties-3.2.3/lib/rails/application/finisher.rb あたりを参考に
    Rails.application.reloaders.each{|reloader| reloader.execute_if_updated }

    # machinist gem を利用してる場合、blueprints を再度読み直す
    # load "#{File.dirname(__FILE__)}/support/blueprints.rb"
  end
end
