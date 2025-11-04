# frozen_string_literal: true

module Alchemrest
  module Transforms
    class ToDecimal < Morpher::Transform
      def call(input)
        success(BigDecimal(input, 0))
      rescue TypeError, ArgumentError
        cannot_make_decimal(input)
      end

      def cannot_make_decimal(input)
        failure(
          error(
            message: "Expected #{input} to be castable to BigDecimal",
            input:,
          ),
        )
      end
    end
  end
end
