# frozen_string_literal: true

module Alchemrest
  module Transforms
    class FromType
      class EmptyToTypeTransformRegistry < BaseToTypeTransformRegistry
        # mutant:disable
        def build_transforms
          {}
        end
      end
    end
  end
end
