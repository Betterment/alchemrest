# frozen_string_literal: true

require 'active_support/time'

module Alchemrest
  module Transforms
    class IsoTime < Morpher::Transform
      include Anima.new(:to_timezone, :require_offset)

      def call(input)
        return not_a_valid_iso_string(input) unless input.instance_of?(String)
        return missing_required_offset(input) unless has_offset?(input) || !require_offset

        begin
          success(parse(input))
        rescue ArgumentError
          not_a_valid_iso_string(input)
        end
      end

      private

      def parse(input)
        if to_timezone
          ActiveSupport::TimeZone[to_timezone].iso8601(input)
        else
          Time.iso8601(input)
        end
      end

      def has_offset?(input)
        parts = input.split("T")
        time = parts.last
        # checking for an offset

        /[Z+-]/.match?(time)
      end

      def missing_required_offset(input)
        failure(
          error(
            message: "Expected #{input} to have a valid ISO timezone offset",
            input: input,
          ),
        )
      end

      def not_a_valid_iso_string(input)
        failure(
          error(
            message: "Expected #{input} to be iso datetime string",
            input: input,
          ),
      )
      end
    end
  end
end
