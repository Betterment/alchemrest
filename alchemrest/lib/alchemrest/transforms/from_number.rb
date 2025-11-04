# frozen_string_literal: true

module Alchemrest
  module Transforms
    class FromNumber < FromType
      OVERRIDES = { type: T.any(Integer, Float) }.freeze
      CONSTRAINT_BUILDER_CLASS = ConstraintBuilder::ForNumber

      def initialize(args = {})
        super(**args, **OVERRIDES)
      end

      def where(constraint_or_description = nil, &block)
        if constraint_or_description
          super
        elsif block
          raise ArgumentError, "Must provide a constraint or description"
        else
          self
        end
      end

      def output_type_name
        "Number"
      end

      delegate(*CONSTRAINT_BUILDER_CLASS::CONSTRAINT_METHODS, to: :constraint_builder)

      private

      def constraint_builder
        CONSTRAINT_BUILDER_CLASS.new(self)
      end

      def transform
        Sequence.new([
          JsonNumber.new,
          validate_constraints,
        ])
      end

      memoize def to_type_transform_registry
        ToTypeTransformRegistry.new(self)
      end
    end
  end
end
