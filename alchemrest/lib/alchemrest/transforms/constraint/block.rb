# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class Block < self
        include Concord.new(:description, :block)
        public :description

        def initialize(description, &block)
          raise ArgumentError, "Must include a predicate block" unless block

          super(description, block)
        end

        def meets_conditions?(input)
          block.call(input)
        end
      end
    end
  end
end
