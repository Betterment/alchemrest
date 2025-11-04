# frozen_string_literal: true

module Alchemrest
  class Request
    class Returns < Module
      include Concord::Public.new(:domain_type, :path_to_payload, :allow_empty_response)

      def included(request_class)
        transformer_methods = Module.new
        returns = self

        transformer_methods.define_method(:response_transformer) do
          super()
            .append(Response::Pipeline::ExtractPayload.new(returns.path_to_payload, returns.allow_empty_response))
            .append(returns.domain_type::TRANSFORM)
        end

        transformer_methods.define_method(:capture_transformer) do
          super()
            .replace_with(Response::Pipeline::Sanitize, returns.sanitize_step)
            .append(returns.omit_step)
        end

        request_class.include(transformer_methods)
      end

      def sanitize_step
        Response::Pipeline::Sanitize.new(
          safe: HashPath.build_collection(capture_configuration.safe_paths),
        )
      end

      def omit_step
        Response::Pipeline::Omit.new(
          HashPath.build_collection(capture_configuration.omitted_paths),
        )
      end

      private

      def capture_configuration
        domain_type.capture_configuration.with_path_to_payload(path_to_payload)
      end
    end
  end
end
