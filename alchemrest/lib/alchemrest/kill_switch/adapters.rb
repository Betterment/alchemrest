# frozen_string_literal: true

require 'active_record'

module Alchemrest
  class KillSwitch
    module Adapters
      class Test
        class Record
          include Anima.new(:enabled)

          alias enabled? enabled
        end

        private_constant :Record

        def initialize
          @records = {}
        end

        def ready?
          true
        end

        def active?(service_name:)
          load_record(service_name:).enabled?
        end

        def activate(service_name:)
          set(service_name:, enabled: true)
        end

        def deactivate(service_name:)
          set(service_name:, enabled: false)
        end

        private

        def set(service_name:, enabled:)
          record = load_record(service_name:).with(enabled:)
          @records[service_name] = record
        end

        def load_record(service_name:)
          raise 'service_name cannot be nil' unless service_name

          @records[service_name] ||= Record.new enabled: false
        end
      end

      class ActiveRecord
        class Record < ::ActiveRecord::Base
          self.table_name = 'alchemrest_kill_switches'
        end

        private_constant :Record

        def ready?
          Record.table_exists?
        end

        def active?(service_name:)
          load_record(service_name:).enabled?
        end

        def activate(service_name:)
          set(service_name:, enabled: true)
        end

        def deactivate(service_name:)
          set(service_name:, enabled: false)
        end

        private

        def set(service_name:, enabled:)
          load_record(service_name:).update!(enabled:)
        end

        def load_record(service_name:)
          raise 'service_name cannot be nil' unless service_name

          Record.find_or_create_by!(service_name:)
        end
      end
    end
  end
end
