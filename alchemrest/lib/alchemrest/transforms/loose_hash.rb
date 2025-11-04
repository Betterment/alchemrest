# frozen_string_literal: true

module Alchemrest
  module Transforms
    class LooseHash < Morpher::Transform
      include Anima.new(:allow_additional_properties, :optional, :required)

      KEY_MESSAGE = 'Missing keys: %<missing>s, Unexpected keys: %<unexpected>s'
      PRIMITIVE   = Primitive.new(::Hash)

      private_constant(*constants(false))

      # Apply transformation to input
      #
      # @param [Object] input
      #
      # @return [Either<Error, Object>]
      def call(input)
        PRIMITIVE
          .call(input)
          .lmap { |e| lift_error(e) }
          .bind { |o| reject_keys(o) }
          .bind { |o| transform(o) }
      end

      private

      def transform(input)
        transform_required(input).bind do |required|
          transform_optional(input).fmap(&required.public_method(:merge))
        end
      end

      def transform_required(input)
        transform_keys(required, input)
      end

      memoize def defaults
        optional.map(&:value).product([nil]).to_h
      end

      def transform_optional(input)
        transform_keys(
          optional.select { |key| input.key?(key.value) },
          input,
        ).fmap(&defaults.public_method(:merge))
      end

      def transform_keys(keys, input)
        success(
          keys
            .to_h do |key|
              [
                key.value,
                coerce_key(key, input).from_right do |error|
                  return failure(error)
                end,
              ]
            end,
        )
      end

      def coerce_key(key, input)
        key.call(input.fetch(key.value)).lmap do |error|
          error(input: input, cause: error)
        end
      end

      def reject_keys(input)
        keys = input.keys
        unexpected = allow_additional_properties ? [] : (keys - allowed_keys)
        missing    = required_keys - keys
        unexpected_properties_exist = allow_additional_properties || unexpected.empty?

        if unexpected_properties_exist && missing.empty?
          success(input)
        else
          failure(
            error(
              input: input,
              message: format(KEY_MESSAGE, missing: missing, unexpected: unexpected),
            ),
          )
        end
      end

      memoize def allowed_keys
        required_keys + optional.map(&:value)
      end

      memoize def required_keys
        required.map(&:value)
      end
    end
  end
end
