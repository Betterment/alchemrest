# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class InList < self
        include Concord.new(:list)

        def meets_conditions?(input)
          list.include?(input)
        end

        def description
          "in list #{list}"
        end
      end
    end
  end
end
