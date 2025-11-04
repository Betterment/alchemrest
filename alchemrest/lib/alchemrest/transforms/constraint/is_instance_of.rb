# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class IsInstanceOf < self
        include Concord::Public.new(:klass)

        def meets_conditions?(input)
          input.instance_of?(klass)
        end

        def description
          "is an #{klass}"
        end
      end
    end
  end
end
