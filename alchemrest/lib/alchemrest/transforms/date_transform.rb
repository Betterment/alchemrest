# frozen_string_literal: true

require 'active_support/time'

module Alchemrest
  module Transforms
    class DateTransform < Morpher::Transform
      def call(input)
        if input.instance_of?(String)
          begin
            success(Date.iso8601(input))
          rescue ArgumentError
            not_a_valid_iso_date_string(input)
          end
        else
          not_a_valid_iso_date_string(input)
        end
      end

      def not_a_valid_iso_date_string(input)
        failure(
          error(
            message: "Expected #{input} to be an iso date string",
            input: input,
          ),
        )
      end
    end
  end
end
