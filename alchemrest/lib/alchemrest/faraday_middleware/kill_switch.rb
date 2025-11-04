# frozen_string_literal: true

module Alchemrest
  module FaradayMiddleware
    class KillSwitch < Faraday::Middleware
      attr_reader :service_name

      def initialize(app, options = {})
        @service_name = options.fetch(:service_name)
        super(app)
      end

      def call(env)
        kill_switch = Alchemrest::KillSwitch.new(service_name:)

        raise KillSwitchEnabledError if kill_switch.active?

        app.call(env)
      end
    end
  end
end
