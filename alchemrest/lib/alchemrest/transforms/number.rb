# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Number < Morpher::Transform
      def call(input)
        case input
          when Numeric
            success(input)
          else
            failure_error(input)
        end
      end

      private

      def failure_error(input)
        failure(
          error(
            message: "Expected: Numeric but got #{input.class}",
            input: input,
          ),
        )
      end
    end
  end
end
