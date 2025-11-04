# frozen_string_literal: true

module Alchemrest
  class Client
    class Configuration
      attr_accessor :service_name,
                    :underscore_response_body_keys

      attr_reader :circuit_breaker,
                  :kill_switch_enabled

      def kill_switch_enabled? = kill_switch_enabled

      def initialize
        @underscore_response_body_keys = true
      end

      def connection
        @connection ||= Connection.new(self)
      end

      def freeze
        connection.freeze

        # enable defaults if they haven't been explicitly configured
        unless circuit_breaker
          use_circuit_breaker
        end

        if kill_switch_enabled.nil?
          use_kill_switch
        end

        super()
      end

      def ready?
        frozen?
      end

      def use_circuit_breaker(circuit_breaker_option = nil)
        ensure_service_name!
        raise InvalidConfigurationError, "already called `use_circuit_breaker`" unless circuit_breaker.nil?

        @circuit_breaker = case circuit_breaker_option
                             in CircuitBreaker
                               circuit_breaker_option
                             in Hash => options
                               build_default_circuit_breaker(**options)
                             in true | nil
                               build_default_circuit_breaker
                             in false
                               build_default_circuit_breaker(disabled_when: -> { true })
                           end
      end

      def use_kill_switch(value = true) # rubocop:disable Style/OptionalBooleanParameter
        ensure_service_name!
        raise InvalidConfigurationError, "already called `use_kill_switch`" unless kill_switch_enabled.nil?

        @kill_switch_enabled = value
      end

      private

      def ensure_service_name!
        return if service_name

        unless connection.url
          raise InvalidConfigurationError,
                "You must set `config.service_name` or `config.connection.url` before trying to use circuit breakers or kill switches"
        end

        @service_name = default_service_name
      end

      def default_service_name
        URI(connection.url).hostname
      end

      def build_default_circuit_breaker(options = {})
        CircuitBreaker.new(
          service_name:,
          **options,
        )
      end
    end
  end
end
