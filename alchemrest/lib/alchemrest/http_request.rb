# frozen_string_literal: true

require 'delegate'

module Alchemrest
  class HttpRequest < SimpleDelegator
    extend Memosa

    def initialize(request, client)
      @client = client
      super(request)
    end

    # Have to disable this because mutant wans to
    # push towards `to_str` which is not available in
    # 7.1. Once we drop 7.1 support we can remove
    # mutant:disable
    def url
      @client.connection.url_prefix.to_s.chop + path
    end

    def headers
      { **default_headers, **super() }
    end

    def execute!
      result = Result.for do |try|
        raw_response = try.unwrap make_request!
        transform_response(build_response(raw_response))
      end

      circuit_breaker.monitor!(result:)
      result
    end

    private

    def build_response(raw_response)
      @client.build_response(raw_response)
    end

    memoize def circuit_breaker
      @client.configuration.circuit_breaker
    end

    def make_request!
      return Result::Error(CircuitOpenError.new) if circuit_breaker.open?

      # We have to set the body in the block form, otherwise it will be ignored for
      # delete requests. See https://github.com/lostisland/faraday/issues/693#issuecomment-466086832
      response = @client.connection.public_send(http_method, path, nil, headers) do |req|
        modify_faraday_request(req)
      end
      Result::Ok(response)
    rescue Faraday::Error => e
      handle_faraday_error(e)
    rescue *Alchemrest.rescuable_exceptions => e
      Result::Error(e)
    end

    def modify_faraday_request(req)
      req.body = body unless http_method == 'get'
    end

    def handle_faraday_error(error)
      if error.wrapped_exception.instance_of?(Net::OpenTimeout)
        Result::Error(TimeoutError.new)
      else
        raise RequestFailedError
      end
    rescue Alchemrest::RequestFailedError => e
      Result::Error(e)
    end
  end
end
