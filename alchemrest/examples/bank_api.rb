# typed: true
# frozen_string_literal: true

require 'alchemrest'
require 'active_model'

Time.zone = "Eastern Time (US & Canada)"

require_relative 'bank_api/positive_interest_string'
require_relative 'bank_api/data/user'
require_relative 'bank_api/data/business_account'
require_relative 'bank_api/data/ach'
require_relative 'bank_api/data/card'
require_relative 'bank_api/data/account'
require_relative 'bank_api/data/check'
require_relative 'bank_api/data/product'
require_relative 'bank_api/data/transaction'
require_relative 'bank_api/requests/get_user'
require_relative 'bank_api/requests/delete_user'
require_relative 'bank_api/requests/update_user'
require_relative 'bank_api/requests/get_transactions'
require_relative 'bank_api/requests/post_transaction'
require_relative 'bank_api/requests/get_products'
require_relative 'bank_api/requests/get_business_account'
require_relative 'bank_api/client'
require_relative 'bank_api/root'
require_relative 'bank_api/factories'
require_relative 'bank_api/graph_visualization'

module BankApi
  module Data
  end
end
