# frozen_string_literal: true

module Alchemrest
  class Result
    # Allow support for sorbet runtime type checking
    def self.[](*_types)
      self
    end

    class Ok < self
      def initialize(value) # rubocop:disable Lint/MissingSuper
        self.value = value
      end

      def ==(other)
        other.is_a?(Ok) && other.value == value
      end

      def ok?
        true
      end

      def deconstruct
        [value]
      end

      def deconstruct_keys(_keys)
        { value: }
      end
    end

    class Error < self
      def initialize(error) # rubocop:disable Lint/MissingSuper
        case error
          when String
            self.error = Alchemrest::Error.new(error)
          when *Alchemrest.rescuable_exceptions
            self.error = error
          else
            raise ArgumentError, "Error must be a string or one of the types defined in Alchemrest.rescuable_exceptions"
        end
      end

      def ==(other)
        other.is_a?(Error) && other.error == error
      end

      def ok?
        false
      end

      def deconstruct
        [error]
      end

      def deconstruct_keys(_keys)
        { error: }
      end
    end

    def self.Ok(value)
      Ok.new(value)
    end

    def self.Error(error)
      Error.new(error)
    end

    def self.for
      block_return_value = yield Alchemrest::Result::TryHelpers

      case block_return_value
        in Alchemrest::Result => result
          result
        else
          Alchemrest::Result::Ok.new(block_return_value)
      end
    rescue Alchemrest::Result::Halt => e
      e.error
    end

    def initialize(*)
      raise 'Cannot create an instance of Alchemrest::Result. Use Alchemrest::Result::Ok or Alchemrest::Result::Error instead.'
    end

    def transform
      raise ArgumentError, 'no block given' unless block_given?

      if ok?
        self.class::Ok(yield value)
      else
        self
      end
    end

    # The pattern of raising, rescuing, re-raising, rescuing again, and then handling looks
    # a little weird, but it's necessary to ensure our final result is an Alchemrest::ResultResecued
    # error where `error.cause` contains the original exception. This way we have information on both
    # the stack trace where the api error originated, and the stack trace of where we tried to
    # rescue it.
    def unwrap_or_rescue
      raise ArgumentError, 'no error handler given' unless block_given?

      unwrap_or_raise!
    rescue *Alchemrest.rescuable_exceptions => e
      begin
        raise Alchemrest::ResultRescued, "Alchemrest rescued an unexpected result of type #{error.class}", cause: e
      rescue Alchemrest::ResultRescued => rescued_error
        Alchemrest.handle_rescued_result(rescued_error)
        yield
      end
    end

    def unwrap_or_raise!
      raise error unless ok?

      value
    end

    protected

    attr_reader :value, :error

    private

    attr_writer :value, :error
  end
end
