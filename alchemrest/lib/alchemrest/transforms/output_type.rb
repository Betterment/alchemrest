# frozen_string_literal: true

module Alchemrest
  module Transforms
    # A wrapper around other transforms that provides metadata about the return type of the transform.
    # Note this does not do anything to actually enforce that return type, although we may want to change
    # that in the future. It's main purpose is to provide metadata we can use to inspect the schema of
    # an `Alchemrest::Data` class.
    class OutputType < T::Struct
      const :sorbet_type, T.any(Class, T::Types::Base)
      const :constraints, T::Array[Alchemrest::Transforms::Constraint]

      def self.simple(sorbet_type)
        new(sorbet_type:, constraints: [])
      end

      def graph
        graphs = graph_types.select { |type| has_graph?(type) }.map(&:graph)

        if graphs.size == 1
          graphs.sole
        end
      end

      def with(args)
        OutputType.new({ sorbet_type:, constraints: }.merge(args))
      end

      def ==(other)
        sorbet_type == other.sorbet_type && constraints.to_set == other.constraints.to_set
      end

      private

      def has_graph?(type)
        type.respond_to?(:<=) && type < Data
      end

      def graph_types
        recursively_unwrap_raw_type(sorbet_type)
      end

      def recursively_unwrap_raw_type(type)
        current_types = case type
        in T::Types::Simple
          [type.raw_type]
        in T::Types::TypedArray => array
          [array.type]
        in T::Types::Union => union
          union.types
        else
          [type]
        end

        current_types.map { |current_type|
          if current_type.instance_of?(T::Types::TypedArray) || current_type.instance_of?(T::Types::Simple)
            recursively_unwrap_raw_type(current_type)
          else
            current_type
          end
        }.flatten
      end
    end
  end
end
