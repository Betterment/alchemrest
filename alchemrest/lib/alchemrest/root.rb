# frozen_string_literal: true

module Alchemrest
  class Root
    @@default_params = -> { {} } # rubocop:disable Style/ClassVars

    def self.use_client(client_class)
      client = client_class.new
      define_method(:client) { client }
    end

    def self.request_definitions
      @request_definitions ||= superclass.respond_to?(:request_definitions) ? superclass.request_definitions.dup : {}
    end

    def self.define_request(name, request_class, &block) # rubocop:disable Style/ArgumentsForwarding
      request_definitions[name] = RequestDefinition.new(name, request_class, &block) # rubocop:disable Style/ArgumentsForwarding

      define_method(name) do |params = {}|
        result = build_request(name, params).execute!

        case result
          in Alchemrest::Result::Error[error]
            if self.class.error_handler
              instance_exec(error, &self.class.error_handler)
            end
          else
            nil
        end

        result
      end
    end

    def self.error_handler
      if superclass.respond_to?(:error_handler)
        @error_handler ||= superclass.error_handler
      end
    end

    def self.reset_error_handler!
      @error_handler = nil
    end

    def self.on_alchemrest_error(&block)
      @error_handler = block
    end

    def build_request(name, params = {})
      request_definition = self.class.request_definitions[name]

      raise "No request definition found for #{name}. Did you call `define_request :#{name} in your root class?" unless request_definition

      request = request_definition.build_request(self, params)
      client.build_http_request(request)
    end

    # @abstract Use `.use_client` or override `#client`
    def client
      raise Alchemrest::UndefinedClientError, <<~MSG
        You forgot to specify a client. You can simply use `use_client` like this:

          class #{self.class} < #{self.class.superclass}
            use_client YourClient
          end

        Or, you can define your client at the instance level:

          class #{self.class} < #{self.class.superclass}
            def client
              YourClient.new
            end
          end
      MSG
    end
  end
end
