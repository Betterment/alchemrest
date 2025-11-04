# frozen_string_literal: true

module Alchemrest
  class Response
    class Pipeline
      # A transform that checks to see if a response was successful, as defined by `response.success?`.
      # If the response is successful, it just returns itself. If not it calls `response.error`.
      # Can be used as the first step in any pipeline's where you want to short circuit execution
      # if the response has an http error code.
      class WasSuccessful < Alchemrest::Response::Pipeline::Transform
        def eql?(other)
          instance_of?(other.class)
        end

        def ==(other)
          instance_of?(other.class)
        end

        def call(response)
          if response.success?
            success(response)
          else
            failure(response.error)
          end
        end
      end
    end
  end
end
