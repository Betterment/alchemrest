# frozen_string_literal: true

module Alchemrest
  module Transforms
    class Constraint
      class IsUuid < MatchesRegex
        REGEX = /\A((?:\h{8})-(?:\h{4})-(?:\h{4})-(?:\h{4})-(?:\h{12}))\z/

        def initialize
          super(REGEX)
        end

        def description
          "is a UUID string"
        end
      end
    end
  end
end
