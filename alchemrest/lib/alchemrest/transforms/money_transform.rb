# frozen_string_literal: true

module Alchemrest
  module Transforms
    class MoneyTransform < Morpher::Transform
      include Concord.new(:unit)

      private_constant(*constants(false))

      def call(input)
        case input
          when Numeric
            success(into_money(input))
          else
            failure_error(input)
        end
      end

      private

      def into_money(amount)
        case unit
          when :cents
            Money.from_cents(amount)
          when :dollars
            Money.from_amount(amount)
          else
            raise "Invalid unit #{unit}"
        end
      end

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
