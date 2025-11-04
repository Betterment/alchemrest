# typed: true
# frozen_string_literal: true

module Alchemrest
  class UrlBuilder
    class Options
      attr_accessor :values, :query

      attr_reader :query_param_encoder

      InvalidEncoderError = Class.new(StandardError)

      def encode_query_with=(name)
        @query_param_encoder = Encoders.find(name)
      rescue NoMatchingPatternError
        raise InvalidEncoderError, ":#{name} is not a known query string encoder type. Known types are :rack and :form"
      end

      def encode_query_with(&)
        @query_param_encoder = Encoders::Custom.new(&)
      end

      def create_builder(template:)
        UrlBuilder.new(
          template:,
          query: query,
          values: values,
          query_param_encoder: query_param_encoder,
        )
      end
    end
  end
end
