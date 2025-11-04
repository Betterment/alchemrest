# frozen_string_literal: true
# typed: true

module BankApi
  module Requests
    class GetBusinessAccount < Alchemrest::Request
      include ActiveModel::Model

      enable_response_capture

      attr_accessor :token, :id

      endpoint :get, '/api/business_accounts/:id' do |url|
        url.values = { id: }
      end

      returns BankApi::Data::BusinessAccount

      def headers
        { Authorization: "Bearer #{token}" }
      end
    end
  end
end
