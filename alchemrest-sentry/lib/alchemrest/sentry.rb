# frozen_string_literal: true

require 'sentry-ruby'

module Alchemrest
  module Sentry
    FILTERED_FOR_SIZE_MESSAGE = { warning: "[FILTERED FOR SIZE]" }.freeze
    TOO_MANY_RESPONSES_MESSAGE = { warning: "[TOO MANY RESPONSES]" }.freeze

    def self.capture_response(identifier:, result:)
      return if should_not_capture?

      response_data = case result
      in Result::Ok(data) if JSON.generate(data).bytesize > 6000
        FILTERED_FOR_SIZE_MESSAGE
      in Result::Ok(data)
        { data: data }
      in Result::Error(error)
        { error: error.to_s }
      end

      response_data = TOO_MANY_RESPONSES_MESSAGE if sentry_klass.get_current_scope.contexts.size > 12 || captured_response_count > 12

      add_response_data!(identifier, response_data)
      sentry_klass.set_tags(includes_captured_alchemrest_response: true)
    end

    def self.add_response_data!(identifier, data)
      ensure_context!(identifier)
      responses = sentry_klass.get_current_scope.contexts.fetch(identifier).fetch(:responses)
      responses << data
    end

    def self.ensure_context!(identifier)
      unless sentry_klass.get_current_scope.contexts.key?(identifier)
        sentry_klass.set_context(identifier, { responses: [] })
      end
    end

    def self.captured_response_count
      sentry_klass.get_current_scope.contexts
        .transform_values { |v| v.key?(:responses) ? v.fetch(:responses).size : 0 }
        .values.sum
    end

    def self.should_not_capture?
      sentry_klass.get_current_scope.contexts.size > 16 || captured_response_count > 16
    end

    def self.sentry_klass
      ::Sentry
    end
  end
end
