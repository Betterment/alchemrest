# frozen_string_literal: true

module Alchemrest
  module Transforms
    class ConstraintBuilder
      class ForNumber < self
        CONSTRAINT_METHODS = %i(greater_than less_than greater_than_or_eq less_than_or_eq positive non_negative integer).freeze

        def greater_than(...) = apply_constraint(Constraint::GreaterThan.new(...))

        def less_than(...) = apply_constraint(Constraint::LessThan.new(...))

        def greater_than_or_eq(...) = apply_constraint(Constraint::GreaterThanOrEq.new(...))

        def less_than_or_eq(...) = apply_constraint(Constraint::LessThanOrEq.new(...))

        def positive = apply_constraint(Constraint::GreaterThan.new(0))

        def non_negative = apply_constraint(Constraint::GreaterThanOrEq.new(0))

        def integer = apply_constraint(Constraint::IsInstanceOf.new(Integer))
      end
    end
  end
end
