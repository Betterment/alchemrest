# frozen_string_literal: true

module Alchemrest
  class Result
    class Halt < StandardError
      attr_reader :error

      def initialize(original_error)
        "Must be an Alchemrest::Result:Error object" unless original_error.is_a? Result::Error
        @error = original_error
        super(original_error.to_s)
      end
    end
  end
end
