# frozen_string_literal: true

require 'mustermann/expander'

module Alchemrest
  class Request
    DEFAULT_HEADERS = IceNine.deep_freeze('User-Agent' => "Alchemrest/#{VERSION}")
    private_constant(:DEFAULT_HEADERS)

    def self.returns(domain_type, path_to_payload: nil, allow_empty_response: false)
      include Returns.new(domain_type, path_to_payload, allow_empty_response)
    end

    def self.endpoint(http_method, template, &block)
      builder_block = block
      endpoint_definition = EndpointDefinition.new(template:, http_method: http_method.to_s, builder_block:)
      include Endpoint.new(endpoint_definition)
    end

    def self.enable_response_capture
      define_method(:response_capture_enabled) { true }
    end

    def self.disable_response_capture
      define_method(:response_capture_enabled) { false }
    end

    def path
      raise NotImplementedError, 'This is an abstract base method. Implement in your subclass.'
    end

    def http_method
      raise NotImplementedError, 'This is an abstract base method. Implement in your subclass.'
    end

    def default_headers
      DEFAULT_HEADERS
    end

    def headers
      {}
    end

    def body
      nil
    end

    def response_transformer
      Response::Pipeline.new(
        Response::Pipeline::WasSuccessful.new,
      )
    end

    def capture_transformer
      Response::Pipeline.new(
        Response::Pipeline::ExtractPayload.new(nil, true),
        Response::Pipeline::Sanitize.new,
      )
    end

    def response_capture_enabled
      true
    end

    def transform_response(response)
      capture!(response:)
      response_transformer.call(response)
    end

    def identifier
      "#{http_method.upcase} #{path}"
    end

    private

    def capture!(response:)
      ResponseCapturedHandler.new(request: self, response:).call
    end
  end
end
