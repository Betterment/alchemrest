# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class LessThan < self
        include Concord.new(:value)

        def meets_conditions?(input)
          input < value
        end

        def description
          "less than #{value}"
        end
      end
    end
  end
end
