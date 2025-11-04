# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/working-with-data" do
  let(:client) { BankApi::Client.new }

  describe "#basic-setup" do
    subject { BankApi::Requests::GetUser.new(id: 1) }
    let(:data) do
      FactoryBot.alchemrest_hash_for(
        :bank_api_user,
        name: "Kevin",
        status: "open",
        date_of_birth: '2021-01-01T00:00:00',
        account_ids: [1, 2, 3],
      )
    end
    let!(:api_request) do
      stub_alchemrest_request(subject)
        .to_return(
          status: 200,
          body: data.to_json,
        )
    end

    it "allows us to access the properties on the returned data class including optional ones" do
      result = client.build_http_request(subject).execute!
      user = result.unwrap_or_raise!
      expect(user.name).to eq("Kevin")
      expect(user.date_of_birth).to eq(Time.utc(2021, 1, 1))
      expect(user.account_ids).to eq([1, 2, 3])
      expect(user.status).to eq("open")

      # optional properties are present but nil when not provided
      expect(user.nickname).to eq(nil)
    end
  end

  describe "#nested-data" do
    subject { BankApi::Requests::GetTransactions.new(id: 1, account_id: 1) }

    let!(:api_request) do
      stub_alchemrest_request(subject)
        .to_return(
          status: 200,
          body: [
            FactoryBot.alchemrest_hash_for(
              :bank_api_transaction,
              :from_check,
            ),
            FactoryBot.alchemrest_hash_for(
              :bank_api_transaction,
              :from_card,
            ),
            FactoryBot.alchemrest_hash_for(
              :bank_api_transaction,
              :from_ach,
            ),
          ].to_json,
        )
    end

    it "returns polymorphic data" do
      result = client.build_http_request(subject).execute!
      transactions = result.unwrap_or_raise!
      expect(transactions.first.source).to be_kind_of(BankApi::Data::Check)
      expect(transactions[1].source).to be_kind_of(BankApi::Data::Card)
      expect(transactions[2].source).to be_kind_of(BankApi::Data::Ach)
    end
  end

  describe "#handling-errors" do
    context "with a response that doesn't match our schema" do
      let!(:api_request) do
        stub_alchemrest_request(subject)
          .to_return(
            status: 200,
            body: { name: "Kevin", status: "reactivated", date_of_birth: '2021-01-01T00:00:00', account_ids: [1, 2, 3] }.to_json,
          )
      end

      subject { BankApi::Requests::GetUser.new(id: 1) }

      it "We get a useful morpher transform error" do
        result = client.build_http_request(subject).execute!
        expect { result.unwrap_or_raise! }
          .to raise_error(
            Alchemrest::MorpherTransformError,
            'Response does not match expected schema - Morpher::Transform::Sequence/2/Alchemrest::Transforms::LooseHash/[:status]/Alchemrest::Transforms::Enum: Expected: enum value from ["open", "locked"] but got: "reactivated"', # rubocop:disable Layout/LineLength
          )
      end
    end
  end

  describe "#handling-empty-responses" do
    let!(:api_request) do
      stub_alchemrest_request(subject)
        .to_return(
          status: 204,
          body: "",
        )
    end

    context "with an endpoint where the response is always empty" do
      subject do
        BankApi::Requests::DeleteUser.new(id: 1)
      end

      it "handles empty responses gracefully" do
        result = client.build_http_request(subject).execute!
        expect(result).to be_a(Alchemrest::Result::Ok)
        expect(result.unwrap_or_raise!).to be_a(Alchemrest::Response)
      end
    end

    context "with an endpoint that conditionally returns empty responses" do
      subject do
        BankApi::Requests::UpdateUser.new(id: 1, name: "Bob", date_of_birth: '2001-01-01')
      end

      it "handles empty responses gracefully and returns nil" do
        result = client.build_http_request(subject).execute!
        expect(result).to be_a(Alchemrest::Result::Ok)
        expect(result.unwrap_or_raise!).to be_nil
      end

      context "when the response is a user" do
        let(:data) do
          FactoryBot.alchemrest_hash_for(
            :bank_api_user,
            name: "Bob",
            status: "open",
            date_of_birth: '2001-01-01T00:00:00',
            account_ids: [1, 2, 3],
          )
        end

        let!(:api_request) do
          stub_alchemrest_request(subject)
            .to_return(
              status: 200,
              body: data.to_json,
            )
        end

        it "returns the user" do
          result = client.build_http_request(subject).execute!
          expect(result).to be_a(Alchemrest::Result::Ok)
          expect(result.unwrap_or_raise!).to be_a(BankApi::Data::User)
        end
      end
    end

    context "with a request not configured for empty responses" do
      subject { BankApi::Requests::GetUser.new(id: 1) }

      it "fails as expected" do
        result = client.build_http_request(subject).execute!
        expect(result).to be_a(Alchemrest::Result::Error)
      end
    end
  end
end
