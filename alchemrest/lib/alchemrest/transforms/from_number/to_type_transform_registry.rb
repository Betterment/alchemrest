# frozen_string_literal: true

module Alchemrest
  module Transforms
    class FromNumber
      class ToTypeTransformRegistry < BaseToTypeTransformRegistry
        def build_transforms
          {
            Money => {
              cents: [MoneyTransform.new(:cents)],
              dollars: [MoneyTransform.new(:dollars)],
            },
          }
        end
      end
    end
  end
end
