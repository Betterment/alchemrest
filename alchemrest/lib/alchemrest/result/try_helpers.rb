# frozen_string_literal: true

module Alchemrest
  class Result
    module TryHelpers
      def self.unwrap(result)
        case result
          in Result::Ok(value)
            value
          else
            raise Result::Halt, result
        end
      end
    end
  end
end
