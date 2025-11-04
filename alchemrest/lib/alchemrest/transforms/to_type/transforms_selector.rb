# frozen_string_literal: true

module Alchemrest
  module Transforms
    class ToType
      class TransformsSelector
        INVALID_KEY_OR_TRANSFORM_ERROR_MESSAGE = "Must provide a symbol key or a Morpher::Transform"
        INVALID_TRANSFORMS_HASH_ERROR_MESSAGE = "transform_options must a Hash with symbol keys, and values of Morpher::Transform[]"

        include Concord.new(:from, :to, :transform_options)

        def initialize(*)
          super
          unless transform_options_valid?
            raise ArgumentError, INVALID_TRANSFORMS_HASH_ERROR_MESSAGE
          end
        end

        def using(key_or_transform)
          raise ArgumentError, INVALID_KEY_OR_TRANSFORM_ERROR_MESSAGE unless a_symbol_or_transform?(key_or_transform)

          transforms_to_use = resolve_transforms_array(key_or_transform)

          unless transforms_to_use
            raise NoTransformOptionForNameError.new(from:, to:, name: key_or_transform, options: transform_options)
          end

          ToType.new(from:, to:, use: transforms_to_use)
        end

        def options
          transform_options.keys
        end

        private

        def transform_options_valid?
          transform_options.instance_of?(Hash) &&
            transform_options.keys.all?(Symbol) &&
            transform_options.values.all? { |value| transform_array?(value) }
        end

        def a_symbol_or_transform?(value)
          value.instance_of?(Symbol) || value.is_a?(Morpher::Transform)
        end

        def transform_array?(value)
          value.instance_of?(Array) && value.all?(Morpher::Transform)
        end

        def resolve_transforms_array(value)
          if value.is_a?(Morpher::Transform)
            [value]
          elsif transform_options.key?(value)
            transform_options.fetch(value)
          end
        end
      end
    end
  end
end
