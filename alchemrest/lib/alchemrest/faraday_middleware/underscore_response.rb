# frozen_string_literal: true

module Alchemrest
  module FaradayMiddleware
    class UnderScoreResponse < Faraday::Middleware
      def on_complete(env)
        env.body = deep_transform_keys!(env.body)
      end

      private

      def deep_transform_keys!(object)
        case object
          when Array
            object.each { |item| deep_transform_keys!(item) }
          when Hash
            object.deep_transform_keys! { |k| k.to_s.underscore }
          else
            object
        end
      end
    end
  end
end
