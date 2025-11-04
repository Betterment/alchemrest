# frozen_string_literal: true

module Alchemrest
  module Transforms
    # The Alchemrest::Transforms::Constraint class is an abstract base that all other constraints should inherit from
    # A constraint is basically just a predicate with metadata. The `meets_conditions?` method is the actual predicate,
    # and description is a human-readable phrase that describes that predicate. We recommend using a phrase that will
    # read well in a sentence like "<input> does not meet the constraint <description>", since that is how it will
    # display in error messages
    class Constraint
      include AbstractType

      abstract_method :meets_conditions?
      abstract_method :description
    end
  end
end
