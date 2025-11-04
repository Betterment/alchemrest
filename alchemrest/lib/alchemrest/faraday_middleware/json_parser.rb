# frozen_string_literal: true

module Alchemrest
  module FaradayMiddleware
    class JsonParser < Faraday::Middleware
      DEFAULT_RESPONSE = '{}'

      def on_complete(env)
        # stash the body for debugging
        env[:raw_body] = env.body

        env.body = if env.parse_body?
                     parse_body(env.body)
                   else
                     {}
                   end
      rescue MultiJson::ParseError
        env.body = {}
      end

      def parse_body(raw_body)
        MultiJson.load(parseable_body(raw_body))
      end

      def parseable_body(raw_body)
        raw_body.presence || DEFAULT_RESPONSE
      end
    end
  end
end
