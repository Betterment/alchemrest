# frozen_string_literal: true

require "pry"
require "factory_bot"
require "sentry-ruby"
require "sentry/test_helper"
require "alchemrest"
require 'webmock/rspec'
require 'alchemrest_integration_helpers'
require 'alchemrest/cop'
require 'support/kill_switch_shared_examples'
require 'support/constrainable_examples'
require 'timecop'
require 'moneta'
require 'rubocop/rspec/support'

require_relative '../examples/bank_api'

AlchemrestIntegrationHelpers.enable_test_adapter
Alchemrest.kill_switch_adapter = Alchemrest::KillSwitch::Adapters::Test.new
Alchemrest.deprecator.behavior = :raise

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include Alchemrest::WebmockHelpers
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include AlchemrestIntegrationHelpers
  config.include Sentry::TestHelper
  config.around(:each) do |example|
    AlchemrestIntegrationHelpers.reset!
    example.run
  end

  config.before(:suite) do
    ENV['SENTRY_DSN'] = 'http://12345:67890@sentry.localdomain/sentry/42'

    Sentry.init do |c|
      c.dsn = 'http://12345:67890@sentry.localdomain/sentry/42'
      c.logger = Logger.new(nil)
      c.background_worker_threads = 0
      c.transport.transport_class = Sentry::DummyTransport
    end
  end

  config.around(:each, :ignore_deprecations) do |example|
    deprecation_count = 0
    original_behavior = Alchemrest.deprecator.behavior
    Alchemrest.deprecator.behavior = ->(_message, _callstack, _deprecation_horizon, _gem_name) { deprecation_count += 1 }

    error = example.run

    Alchemrest.deprecator.behavior = original_behavior

    if error.nil? && deprecation_count.zero?
      raise %(
        The test "#{example.description}" is tagged to ignore deprecations,
        but no deprecations were found. If the tag is not necessary anymore,
        please remove it
      )
    end
  end
end

RSpec::Matchers.define_negated_matcher :not_change, :change
