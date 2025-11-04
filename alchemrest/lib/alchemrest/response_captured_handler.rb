# frozen_string_literal: true

module Alchemrest
  class ResponseCapturedHandler
    LEGACY_ON_RESPONSE_CAPTURED_METHOD_DEFINITION_MESSAGE = <<~MSG
      Defining Alchemrest.on_response_captured like

      `Alchemrest.on_response_captured { |data, response, request| ... }` is deprecated.

      Going forward, method defintions should take the form

      `Alchemrest.on_response_captured { |identifier:, result:| ... }`

      where identifier is a string that identifies the http method and endpoint the request was made to
      and result is an `Alchemrest::Result` object that contains the captured response data, or an Error
      instance.
    MSG

    include Anima.new(:request, :response)

    def call
      return unless request.response_capture_enabled

      unless Alchemrest.on_response_captured
        default_capture_method
        return
      end

      case Alchemrest.on_response_captured.arity
        in 3
          legacy_capture_handler
        in 1
          Alchemrest.on_response_captured.call(identifier:, result: capture_pipeline_result)
      end
    end

    private

    def capture_pipeline_result
      request.capture_transformer.call(response)
    end

    def identifier
      request.identifier
    end

    def legacy_capture_handler
      Alchemrest.deprecator.warn LEGACY_ON_RESPONSE_CAPTURED_METHOD_DEFINITION_MESSAGE
      data = case capture_pipeline_result
               in Result::Ok(value)
                 value
               in Result::Error(e)
                 "Error transforming captured response data: #{e}"
             end

      Alchemrest.on_response_captured.call(data, response, request)
    end

    def default_capture_method
      case capture_pipeline_result
        in Result::Ok(value: data)
          Alchemrest.logger.info("Captured Alchemrest response for '#{identifier}': '#{data}'")
        in Result::Error({error:})
          Alchemrest.logger.error("Failed to capture Alchemrest response for '#{identifier}': '#{error}'")
      end
    end
  end
end
