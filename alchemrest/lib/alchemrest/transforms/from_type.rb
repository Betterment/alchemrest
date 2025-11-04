# frozen_string_literal: true

module Alchemrest
  module Transforms
    # Base class for transforms where we want to validate that the input is a particular
    # type before operating on it. Additional validations can be chained off by use of the
    # #where method. On success this transform will return the input, unchanged. For a transform
    # that will actually change the input into something else, you can call #to and pass a block
    # which will return a `ToType` transform that will run this transform, and then your block.
    class FromType < Morpher::Transform
      include Alchemrest::Transforms::Constrainable.new(additional_attributes: %i(type))
      include Adamantium::Mutable
      DEFAULTS = { constraints: [] }.freeze

      def initialize(args)
        super(**DEFAULTS.merge(args))
      end

      def output_type
        OutputType.new(sorbet_type: type, constraints:)
      end

      def output_type_name
        type.name
      end

      def call(input)
        transform.call(input)
      end

      def to(type, &block)
        if block.nil?
          to_type_transform_registry.resolve(type)
        else
          ToType.using(to: type, from: self, &block)
        end
      rescue Alchemrest::NoRegisteredTransformError
        raise ArgumentError,
          "No transform registered to transform #{output_type.sorbet_type} to #{type}. Perhaps you should use the block form?"
      end

      def array
        Typed.new(transform: super(), output_type: output_type.with(sorbet_type: T::Array[output_type.sorbet_type]))
      end

      def maybe
        Typed.new(transform: super(), output_type: output_type.with(sorbet_type: T.nilable(output_type.sorbet_type)))
      end

      private

      memoize def to_type_transform_registry
        EmptyToTypeTransformRegistry.new(self)
      end

      def transform
        Sequence.new([
          Primitive.new(type),
          validate_constraints,
        ])
      end
    end
  end
end
