# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Enum < Morpher::Transform
      include Concord.new(:values)

      private_constant(*constants(false))

      def call(input)
        case values
          when ::Hash
            evaluate_hash(input)
          when ::Array
            evaluate_array(input)
          else
            failure_error(input)
        end
      end

      private

      def evaluate_array(input)
        if values.include?(input)
          success(input)
        elsif input.is_a?(String) && values.include?(input.to_sym)
          success(input.to_sym)
        else
          failure_error(input)
        end
      end

      def evaluate_hash(input)
        value = values[input]
        if value
          success(value)
        else
          failure_error(input)
        end
      end

      def failure_error(input)
        failure(
          error(
            message: "Expected: enum value from #{values} but got: #{input.inspect}",
            input: input,
          ),
        )
      end
    end
  end
end
