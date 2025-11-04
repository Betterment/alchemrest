# typed: true
# frozen_string_literal: true

module Alchemrest
  class UrlBuilder
    module Encoders
      def self.find(name)
        case name
        in :rack
          RackEncoded.new
        in :form
          FormUrlEncoded.new
        end
      end

      class RackEncoded
        def call(query)
          Rack::Utils.build_nested_query(query)
        end
      end

      class FormUrlEncoded
        def call(query)
          URI.encode_www_form(query)
        end
      end

      class Custom
        def initialize(&block)
          @block = block
        end

        def call(query)
          @block.call(query)
        end
      end
    end
  end
end
