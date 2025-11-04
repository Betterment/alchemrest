# typed: true
# frozen_string_literal: true

module BankApi
  module Requests
    class GetUser < Alchemrest::Request
      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      returns BankApi::Data::User
      endpoint :get, '/api/v1/users/:id' do |url|
        url.values = { id: @id }
        url.query = { includeDetails: true }
      end
      enable_response_capture
    end
  end
end
