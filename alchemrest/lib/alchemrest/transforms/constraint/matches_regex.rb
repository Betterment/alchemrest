# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class MatchesRegex < self
        include Concord.new(:regex)

        def meets_conditions?(input)
          input.match?(regex)
        end

        def description
          "matches #{regex.inspect}"
        end
      end
    end
  end
end
