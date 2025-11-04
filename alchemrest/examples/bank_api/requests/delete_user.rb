# typed: true
# frozen_string_literal: true

module BankApi
  module Requests
    class DeleteUser < Alchemrest::Request
      def initialize(id:)
        @id = id
        super()
      end

      endpoint :delete, '/api/v1/users/:id' do |url|
        url.values = { id: @id }
      end
    end
  end
end
