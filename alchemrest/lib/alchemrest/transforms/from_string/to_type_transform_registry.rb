# frozen_string_literal: true

module Alchemrest
  module Transforms
    class FromString
      class ToTypeTransformRegistry < BaseToTypeTransformRegistry
        def build_transforms
          {
            Time => ToType::FromStringToTimeSelector.new(from),
            Date => [DateTransform.new],
            BigDecimal => [ToDecimal.new],
          }
        end
      end
    end
  end
end
