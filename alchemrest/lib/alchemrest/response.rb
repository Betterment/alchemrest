# frozen_string_literal: true

require 'delegate'
require 'memosa'

module Alchemrest
  class Response < SimpleDelegator
    extend Memosa

    def data
      body
    end

    def to_result
      if success?
        Result.Ok(self)
      else
        error.set_backtrace(caller)
        Result.Error(error)
      end
    end

    def error_details
      "Error with HTTP status: #{status}" unless success?
    end

    def server_error?
      (500..599).cover?(status)
    end

    def client_error?
      (400..499).cover?(status)
    end

    def auth_error?
      [401, 403].include?(status)
    end

    def not_found_error?
      status == 404
    end

    def no_content_response?
      status == 204
    end

    def request_failed?
      status >= 500 && status <= 599
    end

    def timeout?
      false
    end

    def circuit_open?
      false
    end

    memoize def error
      if server_error?
        ServerError.new(self)
      elsif auth_error?
        AuthError.new(self)
      elsif not_found_error?
        NotFoundError.new(self)
      elsif client_error?
        ClientError.new(self)
      else
        ResponseError.new(self)
      end
    end
  end
end
