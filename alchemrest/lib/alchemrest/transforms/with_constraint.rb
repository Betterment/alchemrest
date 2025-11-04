# frozen_string_literal: true

module Alchemrest
  module Transforms
    class WithConstraint < Morpher::Transform
      MESSAGE = %(Input %<actual>p does not meet the constraint "%<description>s")
      include Concord.new(:constraint)

      def initialize(constraint)
        raise ArgumentError, "Must provide an instance of Alchemrest::Transform::Constraint" unless constraint.is_a?(Constraint)

        super
      end

      def call(input)
        if constraint.meets_conditions?(input)
          success(input)
        else
          failure(
            error(input:, message: format(MESSAGE, actual: input, description: constraint.description)),
          )
        end
      end
    end
  end
end
