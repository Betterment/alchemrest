# frozen_string_literal: true

module Alchemrest
  module Transforms
    # A class for taking in an input and transforming it so something else. To initialize this class
    # you must provide a `FromType` transform that first validates that the input is actually transformable
    # (via the `from:` param) and an array of transforms that will actualy do the transformation
    # (via the `use:` param) If you want to run additional validations after transformation, you can use the `#where` method.
    class ToType < Morpher::Transform
      include Alchemrest::Transforms::Constrainable.new(additional_attributes: %i(to from use))
      DEFAULTS = { constraints: [] }.freeze

      def self.using(args, &block)
        new(**args, use: [Success.new(block)])
      end

      def initialize(args)
        super(**DEFAULTS.merge(args))

        raise ArgumentError, ":to must be a Class" unless to.instance_of?(Class)
        raise ArgumentError, ":from must be a FromType transform" unless from.is_a?(FromType)

        unless use.instance_of?(::Array) && !use.empty? && use.all?(Morpher::Transform)
          raise ArgumentError, ":use must be an array of Morpher::Transform instances"
        end
      end

      def output_type
        OutputType.new(sorbet_type: to, constraints: all_constraints)
      end

      def using(transforms)
        with(use: transforms)
      end

      def call(input)
        transform.call(input)
      end

      def all_constraints
        [*from.constraints, *constraints]
      end

      def constraints_for(type)
        raise ArgumentError, "Must provide a Class" unless type.instance_of?(Class)

        unless [self, from].map { |transform| transform.output_type.sorbet_type }.include?(type)
          raise ArgumentError,
            "`type` must be either the to type (#{output_type.sorbet_type}) or the " \
            "from type (#{from.output_type.sorbet_type}), was #{type}"
        end

        [self, from].select { |transform| transform.output_type.sorbet_type == type }.flat_map(&:constraints)
      end

      def array
        Typed.new(transform: super(), output_type: output_type.with(sorbet_type: T::Array[(output_type.sorbet_type)]))
      end

      def maybe
        Typed.new(transform: super(), output_type: output_type.with(sorbet_type: T.nilable(output_type.sorbet_type)))
      end

      private

      def transform
        Sequence.new([
          from,
          *use,
          validate_output,
          validate_constraints,
        ])
      end

      def validate_output
        Block.capture("Alchemrest::Transform::ToType") do |current|
          if current.is_a?(to)
            success(current)
          else
            failure("Transform chain created an ouput of type: #{current.class}. Expected: #{to}")
          end
        end
      end
    end
  end
end
