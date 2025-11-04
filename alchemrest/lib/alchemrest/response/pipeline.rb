# frozen_string_literal: true

module Alchemrest
  class Response
    # The `Alchemrest::Result::Pipeline` is a class that orchestrates running a sequence of
    # `Morpher::Transform` instances starting with an `Alchemrest::Response` instance and ending
    # with an `Alchemrest::Result`. The pipeline is responsible for feeding the output of one
    # transform into the input of the next when a transform succeeds, and wrapping errors in
    # an `Alchemrest::Result::Error` when a transform fails. Transform steps must meet the following
    # criteria
    # 1. Implement a call method
    # 2. Return a `Either::Right` prelude if the transform is successful
    # 3. Return a `Either::Left` prelude that wraps either a `Morpher::Transform::Error` or
    #    one of our `Alchemrest.rescuable_exceptions if the transform is unsuccessful
    class Pipeline
      include Concord::Public.new(:steps)

      def initialize(*steps)
        super(steps)
      end

      def call(response)
        final = steps.reduce(response) do |current, step|
          either = step.call(current)
          return build_error_result(either.from_left) if either.left?
          break either.from_right.value if either.from_right.instance_of?(Final)

          either.from_right
        end

        Result::Ok(final)
      end

      def insert_after(step_class, step)
        index = steps.index { |s| s.instance_of?(step_class) }
        raise ArgumentError, "Step #{step_class} not found" if index.nil?

        self.class.new(*steps.insert(index + 1, step))
      end

      def append(step)
        self.class.new(*steps.append(step))
      end

      def replace_with(step_class, step)
        index = steps.index { |s| s.instance_of?(step_class) }
        raise ArgumentError, "Step #{step_class} not found" if index.nil?

        new_steps = steps.dup
        new_steps[index] = step

        self.class.new(*new_steps)
      end

      private

      def build_error_result(error)
        case error
          when Morpher::Transform::Error
            wrapped_error = Alchemrest::MorpherTransformError.new(error)
            wrapped_error.set_backtrace(caller)
            Alchemrest::Result::Error(wrapped_error)
          when *Alchemrest.rescuable_exceptions
            Alchemrest::Result::Error(error)
          else
            raise "Invalid error object #{error}"
        end
      end
    end
  end
end
