# frozen_string_literal: true

module Alchemrest
  class Data
    class Field
      include Anima.new(:transform, :name, :required)

      def initialize(transform:, name:, required: false)
        unless transform.is_a?(Morpher::Transform) || transform.is_a?(Data)
          raise ArgumentError, "transform must be an instance of Morpher::Transform or Alchemrest::Data, not #{transform.class}"
        end
        raise ArgumentError, "must provide name" unless name
        raise ArgumentError, "must provide non-empty name" if name.to_s.strip.empty?

        @transform = transform
        @name = name.to_s
        @required = required && !transform.instance_of?(Morpher::Transform::Maybe)
      end

      def output_type
        base_type = transform.output_type if transform.respond_to?(:output_type)
        return unless base_type

        if required
          base_type
        else
          base_type.with(sorbet_type: T.nilable(base_type.sorbet_type))
        end
      end

      def constraints
        output_type&.constraints || []
      end
    end
  end
end
