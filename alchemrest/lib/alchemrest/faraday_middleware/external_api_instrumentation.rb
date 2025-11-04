# frozen_string_literal: true

module Alchemrest
  module FaradayMiddleware
    class ExternalApiInstrumentation < Faraday::Middleware
      attr_reader :external_service

      def initialize(app, options = {})
        super(app)
        @external_service = options.fetch(:external_service)
      end

      def call(env)
        ::ActiveSupport::Notifications.instrument(name, env: env, external_service: external_service) do
          @app.call(env)
        end
      end

      def name
        "#{external_service}_api_request"
      end
    end
  end
end
