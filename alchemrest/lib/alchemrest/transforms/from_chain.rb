# frozen_string_literal: true

module Alchemrest
  module Transforms
    module FromChain
      def self.number
        FromNumber.new
      end

      def self.string
        FromString.new
      end
    end
  end
end
