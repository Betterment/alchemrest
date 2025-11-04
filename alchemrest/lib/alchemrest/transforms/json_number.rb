# frozen_string_literal: true

module Alchemrest
  module Transforms
    class JsonNumber < Morpher::Transform
      def call(input)
        if input.instance_of?(Integer) || input.instance_of?(Float)
          success(input)
        else
          failure_error(input)
        end
      end

      private

      def failure_error(input)
        failure(
          error(
            message: "Expected: Float, Integer but got #{input.class}",
            input:,
          ),
        )
      end
    end
  end
end
