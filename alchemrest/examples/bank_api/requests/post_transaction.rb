# frozen_string_literal: true
# typed: true

module BankApi
  module Requests
    class PostTransaction < Alchemrest::Request
      include ActiveModel::Model
      attr_accessor :account_id, :id, :amount

      endpoint :post, '/api/v1/users/:id/accounts/:account_id/transactions' do |url|
        url.values = { id:, account_id: }
      end
      enable_response_capture

      def body
        { amount: }
      end
    end
  end
end
