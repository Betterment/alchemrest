# frozen_string_literal: true

module Alchemrest
  class Error < StandardError
    def deconstruct
      [to_s]
    end

    def deconstruct_keys(_keys)
      { error: to_s }
    end
  end

  class ResponseError < Error
    attr_reader :response

    def initialize(response)
      super
      @response = response
    end

    def to_s
      method = response.env.method
      url = response.env.url
      [
        "HTTP #{response.status} for #{method.upcase} #{url}",
        response.error_details.to_s,
      ].compact.join(" - ")
    end

    def deconstruct
      [response.status, response.error_details]
    end

    def deconstruct_keys(_keys)
      { status: response.status, error: response.error_details }
    end
  end

  class ServerError < ResponseError
    attr_reader :response, :cause

    def initialize(response, cause = nil)
      @response = response
      @cause = cause
      super(response)
    end

    def to_s
      if response.circuit_open?
        "CIRCUIT OPEN"
      elsif response.timeout?
        "#{response.status} timeout"
      else
        error_message
      end
    end

    private

    def error_message
      method = response.env.method
      url = response.env.url
      [
        "HTTP #{response.status} for #{method.upcase} #{url}",
        response.error_details.to_s,
        cause,
      ].compact.join(" - ")
    end
  end

  class ClientError < ResponseError; end

  class AuthError < ClientError; end

  class NotFoundError < ClientError; end

  class UndefinedClientError < Error; end

  class RequestFailedError < Error; end

  class TimeoutError < RequestFailedError; end

  class TransformError < Error; end

  class ResultRescued < Error; end

  class CircuitOpenError < Error; end

  class MorpherTransformError < Error
    attr_reader :error

    def initialize(error)
      @error = error
      super()
    end

    def to_s
      "Response does not match expected schema - #{error.compact_message}"
    end
  end

  class ResponsePipelineError < Error; end

  class InvalidConfigurationError < Error; end

  class ConfigurationNotReadyError < Error; end

  class KillSwitchEnabledError < Error; end

  class NoRegisteredTransformError < Error
    def initialize(from:, to:)
      super("No registered transform for #{from.output_type_name} -> #{to}")
    end
  end

  class NoTransformOptionForNameError < Error
    def initialize(from:, to:, name:, options:)
      super("No transform named #{name} for #{from.output_type_name} -> #{to}. Available options: #{options.keys.join(', ')}")
    end
  end
end
