# frozen_string_literal: true

module Alchemrest
  module Transforms
    class BaseToTypeTransformRegistry
      include AbstractType
      include Concord.new(:from)

      abstract_method :build_transforms

      def initialize(*args)
        super
        @registry_hash = build_internal_registry_hash(build_transforms)
      end

      def resolve(type)
        if @registry_hash.key?(type)
          @registry_hash.fetch(type)
        else
          raise NoRegisteredTransformError.new(from:, to: type)
        end
      end

      private

      def build_internal_registry_hash(transforms)
        transforms.to_h do |type, value|
          new_value = if value.instance_of?(Array)
                        ToType.new(from:, to: type, use: value)
                      elsif value.instance_of?(Hash)
                        ToType::TransformsSelector.new(from, type, value)
                      elsif value.is_a?(ToType::TransformsSelector)
                        value
                      else
                        raise "Not a valid implementation of `def build_transforms`"
                      end
          [type, new_value]
        end
      end
    end
  end
end
