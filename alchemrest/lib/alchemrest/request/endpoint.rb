# frozen_string_literal: true

module Alchemrest
  class Request
    class Endpoint < Module
      include Concord::Public.new(:endpoint_definition)

      def included(_)
        endpoint = self

        define_method(:endpoint_definition) do
          endpoint.endpoint_definition
        end

        include(InstanceMethods)
      end

      module InstanceMethods
        def path
          endpoint_definition.url_for(self)
        end

        def http_method
          endpoint_definition.http_method
        end
      end
    end
  end
end
