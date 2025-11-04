# frozen_string_literal: true

module Alchemrest
  class KillSwitch
    include Anima.new(:service_name)

    def initialize(service_name:)
      raise ArgumentError, 'service_name is required' unless service_name

      super
    end

    def active?
      adapter.active?(service_name:)
    end

    def activate!
      adapter.activate(service_name:)
    end

    def deactivate!
      adapter.deactivate(service_name:)
    end

    private

    def adapter
      Alchemrest.kill_switch_adapter
    end
  end
end
