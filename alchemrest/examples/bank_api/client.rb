# frozen_string_literal: true
# typed: true

class BankApi::Client < Alchemrest::Client
  configure do |config|
    config.connection.url = 'http://bank.example.com'
    config.service_name = "bank"
    config.use_kill_switch(true)
    config.use_circuit_breaker(disabled_when: -> { ENV.fetch("DISABLE_BANK_API_CIRCUIT", nil) })
    config.connection.customize do |c|
      c.options[:open_timeout] = 4
      c.options[:timeout] = 10
    end
  end

  def build_response(raw_response)
    Response.new(raw_response)
  end

  class Response < Alchemrest::Response
    def error_details
      error_data = body.fetch("errors", {})
      case error_data
      when Hash
        error_data.symbolize_keys
      else
        error_data
      end
    end
  end
end
