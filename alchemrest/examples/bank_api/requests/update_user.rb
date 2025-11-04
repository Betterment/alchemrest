# typed: true
# frozen_string_literal: true

module BankApi
  module Requests
    class UpdateUser < Alchemrest::Request
      def initialize(id:, name:, date_of_birth:)
        @id = id
        @name = name
        @date_of_birth = date_of_birth
        super()
      end

      endpoint :patch, '/api/v1/users/:id' do |url|
        url.values = { id: @id }
      end

      def body
        {
          name: @name,
          date_of_birth: @date_of_birth,
        }
      end

      returns BankApi::Data::User, allow_empty_response: true
    end
  end
end
