# frozen_string_literal: true

module Alchemrest
  module Transforms
    # Calling Constrainable.with_additional_attributes(...) will return a module that
    # can be included in a `Morpher::Transform` class to allow adding validation constraints
    # using the `#where` method. We do this in both `ToType` and `FromType`
    class Constrainable < Anima
      def initialize(args = {})
        additional_attributes = args[:additional_attributes]
        super(*additional_attributes, :constraints)
      end

      def included(base)
        base.include(InstanceMethods)
        super
      end

      module InstanceMethods
        def where(constraint_or_description, &block)
          constraint = if block
                         Constraint::Block.new(constraint_or_description, &block)
                       elsif constraint_or_description.is_a?(Constraint)
                         constraint_or_description
                       else
                         raise ArgumentError, "Must provide an instance of Alchemrest::Transform::Constraint"
                       end

          with(constraints: [*constraints, constraint])
        end

        private

        def validate_constraints
          constraints.map { |constraint| WithConstraint.new(constraint) }
            .inject(Morpher::Transform::Sequence.new([])) { |sequence, transform| sequence.seq(transform) }
        end
      end
    end
  end
end
