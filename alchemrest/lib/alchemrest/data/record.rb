# frozen_string_literal: true

module Alchemrest
  class Data
    class Record < Module
      DEFAULTS = {
        required: Morpher::EMPTY_HASH,
        optional: Morpher::EMPTY_HASH,
        allow_additional_properties: true,
      }.freeze

      include Anima.new(:required, :optional, :allow_additional_properties)

      def self.new(**attributes)
        super(**DEFAULTS.merge(attributes))
      end

      # rubocop:disable Metrics/AbcSize
      def included(host)
        optional           = optional()
        optional_transform = transform(optional)
        required           = required()
        required_transform = transform(required)
        additional_properties_allowed = allow_additional_properties

        host.class_eval do
          include Anima.new(*(required.keys + optional.keys))

          const_set(
            :TRANSFORM,
            Transforms::Typed.new(
              transform: Morpher::Transform::Sequence.new(
                [
                  Morpher::Transform::Primitive.new(Hash),
                  Morpher::Transform::Hash::Symbolize.new,
                  Transforms::LooseHash.new(
                    required: required_transform,
                    optional: optional_transform,
                    allow_additional_properties: additional_properties_allowed,
                  ),
                  Morpher::Transform::Success.new(public_method(:new)),
                ],
              ),
              output_type: Transforms::OutputType.simple(host),
            ),
          )
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def transform(attributes)
        attributes.map do |name, transform|
          Morpher::Transform::Hash::Key.new(name, transform)
        end
      end
    end
  end
end
