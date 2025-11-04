# frozen_string_literal: true

module Alchemrest
  class Response
    class Pipeline
      # This base class simply ensures that if
      # a transform returns an alchemrest error that
      # was created but not raised, then we'll set the
      # backtrace so it can be traced to the transform
      # that generated it. Only really relevant for
      # implementors creating custom transforms.
      class Transform < Morpher::Transform
        def failure(error)
          if error.respond_to?(:backtrace) && error.backtrace.nil?
            error.set_backtrace(caller)
          end
          super
        end

        def final(value)
          success(Final.new(value))
        end
      end
    end
  end
end
