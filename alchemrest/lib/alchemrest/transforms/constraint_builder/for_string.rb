# frozen_string_literal: true

module Alchemrest
  module Transforms
    class ConstraintBuilder
      class ForString < self
        CONSTRAINT_METHODS = %i(max_length min_length matches in must_be_uuid).freeze

        def max_length(...) = apply_constraint(Constraint::MaxLength.new(...))

        def min_length(...) = apply_constraint(Constraint::MinLength.new(...))

        def matches(...) = apply_constraint(Constraint::MatchesRegex.new(...))

        def in(...) = apply_constraint(Constraint::InList.new(...))

        def must_be_uuid = apply_constraint(Constraint::IsUuid.new)
      end
    end
  end
end
