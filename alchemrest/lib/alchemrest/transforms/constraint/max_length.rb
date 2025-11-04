# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class MaxLength < self
        include Concord.new(:max_length)

        def meets_conditions?(input)
          input.length <= max_length
        end

        def description
          "max length of #{max_length}"
        end
      end
    end
  end
end
