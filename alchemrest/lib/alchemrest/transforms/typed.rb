# frozen_string_literal: true

module Alchemrest
  module Transforms
    # A wrapper around other transforms that provides metadata about the return type of the transform.
    # Note this does not do anything to actually enforce that return type, although we may want to change
    # that in the future. It's main purpose is to provide metadata we can use to inspect the schema of
    # an `Alchemrest::Data` class.
    class Typed < Morpher::Transform
      include Anima.new(:transform, :output_type)
      include Adamantium::Mutable

      def call(input)
        transform.call(input)
      end

      def array
        Typed.new(
          transform: super(),
          output_type: output_type.with(sorbet_type: T::Array[output_type.sorbet_type]),
        )
      end

      def maybe
        Typed.new(
          transform: super(),
          output_type: output_type.with(sorbet_type: T.nilable(output_type.sorbet_type)),
        )
      end
    end
  end
end
