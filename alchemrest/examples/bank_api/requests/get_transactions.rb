# frozen_string_literal: true

module BankApi
  module Requests
    class GetTransactions < Alchemrest::Request
      include ActiveModel::Model
      attr_accessor :account_id, :id, :amount

      returns BankApi::Data::Transaction[]
      endpoint :get, '/api/v1/users/:id/accounts/:account_id/transactions' do |url|
        url.values = { id:, account_id: }
      end
      enable_response_capture

      def response_transformer
        super.insert_after(
          Alchemrest::Response::Pipeline::ExtractPayload,
          ExtractUserId.new(self),
        )
      end

      class ExtractUserId < Alchemrest::Response::Pipeline::Transform
        def initialize(request)
          super()
          @request = request
        end

        def call(payload)
          success(payload.map { |item| item.merge("user_id" => @request.id) })
        end
      end
    end
  end
end
