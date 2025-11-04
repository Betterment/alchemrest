# frozen_string_literal: true

module Alchemrest
  class Client
    def self.inherited(subclass) # rubocop:disable Lint/MissingSuper
      subclass.class_eval do
        def connection
          self.class.connection
        end

        def self.connection
          @connection ||= configuration.connection.create_new_connection
        end
      end
    end

    def self.configuration
      raise InvalidConfigurationError, "Call `configure` in your client class to setup connection details" unless @configuration

      @configuration
    end

    def self.configure(&configuration_block)
      @configuration = begin
        config = Alchemrest::Client::Configuration.new
        class_exec(config, &configuration_block)
        config.freeze
        config
      end
    end

    def self.kill_switch
      KillSwitch.new(service_name: configuration.service_name)
    end

    def configuration
      self.class.configuration
    end

    def build_http_request(request)
      HttpRequest.new(request, self)
    end

    def build_response(raw_response)
      Response.new(raw_response)
    end
  end
end
