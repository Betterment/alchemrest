# frozen_string_literal: true

module Alchemrest
  module Transforms
    class ConstraintBuilder
      include Concord.new(:constrainable)

      private

      def apply_constraint(constraint)
        constrainable.where(constraint)
      end
    end
  end
end
