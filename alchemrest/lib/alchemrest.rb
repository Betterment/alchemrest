# frozen_string_literal: true

require "morpher"
require "money"
require 'faraday'
require 'multi_json'
require "active_support"
require "active_support/core_ext/hash"
require "active_support/core_ext/object"
require "active_support/parameter_filter"
require "active_support/hash_with_indifferent_access"
require "circuitbox"
require 'sorbet-runtime'
require "rack/utils"
require_relative "alchemrest/version"
require_relative "alchemrest/hash_path"
require_relative "alchemrest/transforms"
require_relative "alchemrest/transforms/constrainable"
require_relative "alchemrest/transforms/from_type"
require_relative "alchemrest/transforms/to_type"
require_relative "alchemrest/transforms/to_type/transforms_selector"
require_relative "alchemrest/transforms/constraint"
require_relative "alchemrest/transforms/constraint_builder"
require_relative "alchemrest/transforms/constraint_builder/for_string"
require_relative "alchemrest/transforms/constraint_builder/for_number"
require_relative "alchemrest/transforms/constraint/block"
require_relative "alchemrest/transforms/with_constraint"
require_relative "alchemrest/data/field"
require_relative "alchemrest/data/graph"
require_relative "alchemrest/data/capture_configuration"
require_relative "alchemrest/data/record"
require_relative "alchemrest/data/schema"
require_relative "alchemrest/data"
require_relative "alchemrest/transforms/base_to_type_transform_registry"
require_relative "alchemrest/transforms/from_type/empty_to_type_transform_registry"

Dir.glob(File.join(__dir__, 'alchemrest', 'transforms', '*.rb')).each do |file|
  require_relative file
end

require_relative "alchemrest/transforms/constraint/matches_regex"
Dir.glob(File.join(__dir__, 'alchemrest', 'transforms', 'constraint', '*.rb')).each do |file|
  require_relative file
end

require_relative "alchemrest/transforms/to_type/from_string_to_time_selector"
require_relative "alchemrest/transforms/from_string/to_type_transform_registry"
require_relative "alchemrest/transforms/from_number/to_type_transform_registry"
require_relative "alchemrest/result"
require_relative 'alchemrest/result/halt'
require_relative 'alchemrest/result/try_helpers'
require_relative "alchemrest/error"
require_relative "alchemrest/response"
require_relative "alchemrest/response/pipeline"
require_relative "alchemrest/response/pipeline/transform"
require_relative "alchemrest/response/pipeline/was_successful"
require_relative "alchemrest/response/pipeline/final"
require_relative "alchemrest/response/pipeline/extract_payload"
require_relative "alchemrest/response/pipeline/sanitize"
require_relative "alchemrest/response/pipeline/omit"
require_relative "alchemrest/response_captured_handler"
require_relative "alchemrest/client/configuration/connection"
require_relative "alchemrest/client/configuration"
require_relative "alchemrest/client"
require_relative "alchemrest/url_builder"
require_relative "alchemrest/url_builder/encoders"
require_relative "alchemrest/url_builder/options"
require_relative "alchemrest/endpoint_definition"
require_relative "alchemrest/request/endpoint"
require_relative "alchemrest/request/returns"
require_relative "alchemrest/request"
require_relative "alchemrest/request_definition"
require_relative "alchemrest/request_definition/builder"
require_relative "alchemrest/root"
require_relative "alchemrest/kill_switch"
require_relative "alchemrest/kill_switch/adapters"
require_relative "alchemrest/circuit_breaker"
require_relative "alchemrest/http_request"
require_relative "alchemrest/faraday_middleware/json_parser"
require_relative "alchemrest/faraday_middleware/underscore_response"
require_relative "alchemrest/faraday_middleware/external_api_instrumentation"
require_relative "alchemrest/faraday_middleware/kill_switch"
require_relative "alchemrest/webmock_helpers"
require_relative "alchemrest/factory_bot"
require_relative "alchemrest/railtie"

module Alchemrest
  DEFAULT_RESCUABLE_EXCEPTIONS = [Alchemrest::Error].freeze

  DEFAULT_FILTER_PARAMETERS = %i(ssn password token).freeze

  @filter_parameters = DEFAULT_FILTER_PARAMETERS

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  def self.logger=(logger)
    @logger = logger
  end

  # mutant:disable
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("3.0", "Alchemrest")
  end

  def self.filter_parameters
    @filter_parameters
  end

  def self.filter_parameters=(params)
    @filter_parameters = params.uniq
  end

  def self.parameter_filter
    ActiveSupport::ParameterFilter.new(@filter_parameters)
  end

  def self.on_result_rescued(&block)
    @on_result_rescued = block if block
  end

  def self.on_response_captured(&block)
    @on_response_captured = block if block
    @on_response_captured
  end

  def self.restore_default_result_rescue_behavior
    @on_result_rescued = nil
  end

  def self.restore_default_response_capture_behavior
    @on_response_captured = nil
  end

  def self.handle_rescued_result(error)
    if @on_result_rescued
      @on_result_rescued.call(error)
    else
      logger.warn(error.to_s)
    end
  end

  def self.rescuable_exceptions
    @rescuable_exceptions || DEFAULT_RESCUABLE_EXCEPTIONS
  end

  def self.rescuable_exceptions=(exceptions)
    @rescuable_exceptions = exceptions
  end

  def self.kill_switch_adapter
    @kill_switch_adapter ||= KillSwitch::Adapters::ActiveRecord.new
  end

  def self.kill_switch_adapter=(adapter)
    @kill_switch_adapter = adapter
  end
end
