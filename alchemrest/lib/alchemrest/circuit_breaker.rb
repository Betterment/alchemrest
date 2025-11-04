# frozen_string_literal: true

module Alchemrest
  class CircuitBreaker
    extend Memosa
    include Anima.new(
      :service_name,
      :sleep_window,
      :time_window,
      :error_threshold,
      :volume_threshold,
      :disabled_when,
    )

    class RequestFailed < StandardError; end

    DEFAULTS = {
      # number of seconds the circuit stays open once we pass the error threshold
      sleep_window: 90,
      # length of interval (in seconds) over which it calculates the error rate
      time_window: 60,
      # number of requests within `time_window` seconds before it calculates
      # error rates (checked on failures)
      volume_threshold: 5,
      # exceeding this rate will open the circuit (checked on failures)
      error_threshold: 50,
      disabled_when: nil,
    }.freeze

    def initialize(args)
      super(**DEFAULTS, **args)
    end

    def enabled?
      !service_name.nil? && (disabled_when.nil? || !disabled_when.call)
    end

    def open?
      enabled? && circuit_box.open?
    end

    def monitor!(result:)
      return unless enabled?

      outcome = circuit_box.run(exception: false) do
        raise RequestFailed if request_failed?(result:)

        :success
      end

      outcome || :failure
    end

    private

    def request_failed?(result:)
      case result
        in Alchemrest::Result::Error(Alchemrest::ServerError | Alchemrest::RequestFailedError)
          true
        else
          false
      end
    end

    memoize def circuit_box
      Circuitbox.circuit(service_name, circuit_box_options)
    end

    def circuit_box_options
      {
        # number of seconds the circuit stays open once we pass the error threshold
        sleep_window:,
        # length of interval (in seconds) over which it calculates the error rate
        time_window:,
        # number of requests within `time_window` seconds before it calculates
        # error rates (checked on failures)
        volume_threshold:,
        # exceeding this rate will open the circuit (checked on failures)
        error_threshold:,
        exceptions: [RequestFailed],
      }
    end
  end
end
