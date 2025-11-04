# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/writing-tests" do
  describe "#testing-data-classes" do
    it "allows us to build an object from a hash" do
      transaction = BankApi::Data::Transaction.from_hash(
        user_id: 1,
        amount_cents: 120_00,
        status: "completed",
        settled_at: "2023-10-10T00:00:00Z",
        description: "check transaction",
        account_id: "1",
        source: {
          source_type: "check",
          check_number: 100,
          check_image_back_url: "http://bank.example.com/api/v1/check_images/100/back.png",
          check_image_front_url: "http://bank.example.com/api/v1/check_images/100/front.png",
        },
      )

      expect(transaction).to be_a(BankApi::Data::Transaction)
    end

    it "allows us to build an object from a factory" do
      transaction = FactoryBot.alchemrest_record_for(:bank_api_transaction)
      expect(transaction).to be_a(BankApi::Data::Transaction)
    end

    it "allows us to build an object from a factory with traits" do
      transaction = FactoryBot.alchemrest_record_for(:bank_api_transaction, :from_ach, description: "My Special ACH Transaction")
      expect(transaction).to be_a(BankApi::Data::Transaction)
      expect(transaction.source).to be_a(BankApi::Data::Ach)
      expect(transaction.description).to eq("My Special ACH Transaction")
    end

    it "allows us to omit keys when building an object" do
      transaction = FactoryBot.alchemrest_record_for(
        :bank_api_transaction,
        source: Alchemrest::FactoryBot::OmitKey.instance,
      )
      expect(transaction).to be_a(BankApi::Data::Transaction)
      expect(transaction.source).to be_nil
    end
  end
end
