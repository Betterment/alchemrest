# frozen_string_literal: true

module Alchemrest
  class RequestDefinition
    class Builder
      def initialize
        @defaults = {}
      end

      attr_accessor :defaults
    end
  end
end
