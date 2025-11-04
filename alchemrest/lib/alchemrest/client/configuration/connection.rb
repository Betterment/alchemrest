# frozen_string_literal: true

require "faraday/request/json"

module Alchemrest
  class Client
    class Configuration
      class Connection
        attr_accessor :url, :headers, :customize_block
        attr_reader :client_configuration, :use_default_middleware

        def initialize(client_configuration)
          @client_configuration = client_configuration
          @use_default_middleware = true
        end

        def customize(use_default_middleware: true, &block)
          @use_default_middleware = use_default_middleware
          self.customize_block = block
        end

        def create_new_connection
          unless frozen?
            raise ConfigurationNotReadyError, "Don't use configuration to build connections until the configuration has been frozen"
          end

          Faraday.new(url: url, headers: headers) do |c|
            c.use Faraday::Request::Json

            apply_configuration(c)
          end
        end

        def freeze
          validate!
          super
        end

        private

        def use_default_middleware?
          @use_default_middleware
        end

        def use_kill_switch?
          client_configuration.kill_switch_enabled?
        end

        def underscore_response_body_keys?
          client_configuration.underscore_response_body_keys
        end

        def kill_switch_adapter_ready?
          Alchemrest.kill_switch_adapter.ready?
        end

        def validate!
          raise InvalidConfigurationError, "No url provided" if url.blank?
        end

        def apply_configuration(connection)
          customize_block.call(connection) if customize_block
          apply_middleware(connection)
        end

        def apply_middleware(connection)
          if use_default_middleware?
            if client_configuration.service_name
              if use_kill_switch? && kill_switch_adapter_ready?
                connection.use FaradayMiddleware::KillSwitch, service_name: client_configuration.service_name
              end

              connection.use FaradayMiddleware::ExternalApiInstrumentation, external_service: client_configuration.service_name
            end

            connection.use FaradayMiddleware::UnderScoreResponse if underscore_response_body_keys?
            connection.use FaradayMiddleware::JsonParser
          end
        end
      end
    end
  end
end
