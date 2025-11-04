# frozen_string_literal: true

require 'active_support/time'

module Alchemrest
  module Transforms
    class EpochTime < Morpher::Transform
      include Concord.new(:unit)

      def call(input)
        if input.is_a?(Integer)
          as_seconds = case unit
                         when :seconds
                           input
                         when :milliseconds
                           input / 1000
                         else
                           raise "Invalid unit #{unit}"
                       end
          success(Time.at(as_seconds).in_time_zone("UTC"))
        else
          failure(
            error(
              message: "Expected #{input} to be an epoch integer",
              input: input,
            ),
        )
        end
      end
    end
  end
end
