# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class GreaterThanOrEq < self
        include Concord.new(:value)

        def meets_conditions?(input)
          input >= value
        end

        def description
          "greater than or equal to #{value}"
        end
      end
    end
  end
end
