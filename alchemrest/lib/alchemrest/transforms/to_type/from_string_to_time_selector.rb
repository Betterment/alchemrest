# frozen_string_literal: true

module Alchemrest
  module Transforms
    class ToType
      class FromStringToTimeSelector < TransformsSelector
        def initialize(from)
          super(from, nil, {})
        end

        def using(timezone_identifier, require_offset: true)
          use, to = case timezone_identifier
          in :utc
            [[IsoTime.new(to_timezone: 'UTC', require_offset:)], ActiveSupport::TimeWithZone]
          in :local
            [[IsoTime.new(to_timezone: Time.zone.name, require_offset:)], ActiveSupport::TimeWithZone]
          in :offset
            raise ArgumentError, "require_offset cannot be false when using :offset" unless require_offset

            [[IsoTime.new(to_timezone: nil, require_offset: true)], Time]
          in String
            [[IsoTime.new(to_timezone: timezone_identifier, require_offset:)], ActiveSupport::TimeWithZone]
          end
          ToType.new(from:, to:, use:)
        end
      end
    end
  end
end
