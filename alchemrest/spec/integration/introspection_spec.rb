# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/introspection" do
  describe "#putting-it-all-together" do
    it "allows us to visualize the graph" do
      expected_string = <<~TREE
        BankApi::Data::Account
        - name => String
        - status => T.any(String, Symbol)
        - cards => T::Array[BankApi::Data::Card]
        - nickname => T.nilable(String)
        - cards
          BankApi::Data::Card
          - source_type => T.any(String, Symbol)
          - card_number => String
          - expiration_date => ActiveSupport::TimeWithZone
        BankApi::Data::Ach
        - source_type => T.any(String, Symbol)
        - trace_number => String
          * max length of 15
        BankApi::Data::BusinessAccount
        - name => String
        - status => T.any(String, Symbol)
        - ein => String
        - id => String
        - nickname => T.nilable(String)
        BankApi::Data::Card
        - source_type => T.any(String, Symbol)
        - card_number => String
        - expiration_date => ActiveSupport::TimeWithZone
        BankApi::Data::Check
        - source_type => T.any(String, Symbol)
        - check_number => Integer
        - check_image_back_url => String
        - check_image_front_url => String
        BankApi::Data::Product
        - name => String
        - interest_rate => unknown
        - partner_revenue_rate => BigDecimal
          * matches /^\\d+(?:\\.\\d{1,4})?$/
          * less than 10
        BankApi::Data::Transaction
        - amount_cents => Money
        - status => T.any(String, Symbol)
        - settled_at => ActiveSupport::TimeWithZone
        - description => String
        - account_id => String
        - user_id => T.any(Float, Integer)
        - source => T.nilable(T.any(BankApi::Data::Ach, BankApi::Data::Card, BankApi::Data::Check))
        BankApi::Data::User
        - name => String
        - status => T.any(String, Symbol)
        - date_of_birth => ActiveSupport::TimeWithZone
        - account_ids => T::Array[Integer]
        - nickname => T.nilable(String)
      TREE

      visualization = BankApi::GraphVisualization.new
      expect(visualization.tree_string).to eq(expected_string)
    end
  end
end
