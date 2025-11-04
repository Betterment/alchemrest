# frozen_string_literal: true
# typed: true

module BankApi
  module Requests
    class GetProducts < Alchemrest::Request
      returns BankApi::Data::Product[]
      endpoint :get, '/api/v1/products'
      enable_response_capture
    end
  end
end
