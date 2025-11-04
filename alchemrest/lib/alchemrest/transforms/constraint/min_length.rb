# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class MinLength < self
        include Concord.new(:min_length)

        def meets_conditions?(input)
          input.length >= min_length
        end

        def description
          "min length of #{min_length}"
        end
      end
    end
  end
end
