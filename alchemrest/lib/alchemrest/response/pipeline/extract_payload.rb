# frozen_string_literal: true

module Alchemrest
  class Response
    class Pipeline
      # A transform that can extract a nested payload from a response body. Takes in an
      # array of symbols, strings, or integers that represent the path to the data you care about.
      # This class assumes the response.body is a hash with string keys, so it calls to_s on all
      # non integer path elements.
      class ExtractPayload < Alchemrest::Response::Pipeline::Transform
        include Concord::Public.new(:path_to_payload, :allow_empty_response)

        # # All symbols will be converted to strings, and integers will be left alone.
        # @param path_to_payload [Array<Symbol, String, Integer>] The path to the payload you care about
        # @param _allow_empty_response [bool] Should HTTP 204 OkNoContent empty responses be allowed

        def initialize(_path_to_payload = nil, _allow_empty_response = false) # rubocop:disable Style/OptionalBooleanParameter
          super
        end

        def call(response)
          # If response is empty and the status is 204 (No Content), return nil as the payload
          if response.no_content_response?
            return final(nil) if allow_empty_response?

            return failure(ResponsePipelineError.new("Ok but empty response not allowed"))
          end

          payload = extract_payload(response)
          if payload.nil?
            failure(ResponsePipelineError.new("Response body did not contain expected payload at #{path_to_payload}"))
          else
            success(payload)
          end
        end

        def extract_payload(response)
          if path_to_payload.nil?
            response.data
          else
            normalized_path = path_to_payload.map do |path_element|
              if path_element.is_a?(Integer)
                path_element
              else
                path_element.to_s
              end
            end
            response.data.dig(*normalized_path)
          end
          # If our path tries to dig into a non hash, we'll get a TypeError. We want to rescue that and ensure
          # our code continues to safely return a result.
          rescue TypeError
            nil
        end

        private

        def allow_empty_response?
          allow_empty_response
        end
      end
    end
  end
end
