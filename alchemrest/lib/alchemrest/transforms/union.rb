# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Union < Morpher::Transform
      include Anima.new(:types, :discriminator)

      private_constant(*constants(false))

      def call(input)
        type_key = input&.fetch(discriminator.to_s)
        if type_key.nil?
          klass_not_found_failure_error(input)
        else
          perform_transformation(input, type_key)
        end
      end

      def output_type
        OutputType.simple(T.any(*types.values))
      end

      private

      def perform_transformation(input, type_key)
        klass = types[type_key.to_sym]
        if klass
          klass::TRANSFORM.call(input)
        else
          klass_not_found_failure_error(input)
        end
      end

      def klass_not_found_failure_error(input)
        failure(
          error(
            message: "Expected discriminator #{discriminator} to produce a value which is one of #{types.keys.join(',')} but got #{input&.fetch(discriminator).nil? ? 'nil' : input[discriminator]}", # rubocop:disable Layout/LineLength
            input: input,
          ),
        )
      end
    end
  end
end
