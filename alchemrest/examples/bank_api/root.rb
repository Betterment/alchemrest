# frozen_string_literal: true
# typed: true

class BankApi::Root < Alchemrest::Root
  extend Memosa
  attr_reader :id

  def initialize(id:)
    @id = id
    super()
  end

  use_client BankApi::Client

  define_request :get_user, BankApi::Requests::GetUser do |request|
    request.defaults = { id: }
  end

  define_request :update_user, BankApi::Requests::UpdateUser do |request|
    request.defaults = { id: }
  end

  define_request :delete_user, BankApi::Requests::UpdateUser do |request|
    request.defaults = { id: }
  end

  define_request :post_transaction, BankApi::Requests::PostTransaction do |request|
    request.defaults = { id: }
  end

  define_request :get_transactions, BankApi::Requests::GetTransactions do |request|
    request.defaults = { id: }
  end

  define_request :get_products, BankApi::Requests::GetProducts

  on_alchemrest_error do |error|
    case error
    in { status: 401 }
      Alchemrest.logger.info "Credentials expired"
    else
      nil
    end
  end

  memoize def all_transactions
    Alchemrest::Result.for do |try|
      user = try.unwrap get_user
      user.account_ids.map { |i| try.unwrap get_transactions(account_id: i) }.flatten
    end
  end
end
