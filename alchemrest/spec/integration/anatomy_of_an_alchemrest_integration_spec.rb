# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/anatomy-of-an-alchemrest-integration" do
  describe "#requests" do
    describe "a GET request model" do
      let!(:api_request) do
        stub_alchemrest_request(subject)
          .to_return(
            status: 200,
            body: { name: "Kevin", status: "open", date_of_birth: '2021-01-01T00:00:00', account_ids: [1, 2, 3] }.to_json,
          )
      end

      subject { BankApi::Requests::GetUser.new(id: 1) }
      let(:client) { BankApi::Client.new }

      it "can make a stand alone request and get back a user model" do
        result = client.build_http_request(subject).execute!
        expect(result.unwrap_or_raise!).to be_kind_of(BankApi::Data::User)
      end
    end

    describe "a POST request model" do
      let!(:api_request) do
        stub_alchemrest_request(subject)
          .to_return(status: 204)
      end

      subject { BankApi::Requests::PostTransaction.new(id: 1, account_id: 2, amount: 100) }
      let(:client) { BankApi::Client.new }

      it "can make a stand alone request and get back a user model" do
        result = client.build_http_request(subject).execute!
        expect(result.unwrap_or_raise!).to be_kind_of(BankApi::Client::Response)
        expect(result.unwrap_or_raise!.status).to be(204)
      end
    end

    describe "a request with custom headers" do
      let!(:api_request) do
        stub_alchemrest_request(subject, with_headers: true)
          .to_return(
            lambda do |request|
              if request.headers["Authorization"] == "Bearer A_TOKEN"
                {
                  status: 200,
                  body: FactoryBot.alchemrest_hash_for(:bank_api_business_account).to_json,
                }
              else
                raise "Missing Auth"
              end
            end,
          )
      end

      subject { BankApi::Requests::GetBusinessAccount.new(id: 1, token: "A_TOKEN") }
      let(:client) { BankApi::Client.new }

      it "makes the request with the headers and returns the stub" do
        result = client.build_http_request(subject).execute!
        expect(result.unwrap_or_raise!).to be_kind_of(BankApi::Data::BusinessAccount)
      end
    end
  end

  describe "#data" do
    describe "when we use schema to setup a data model" do
      it "has a from_hash we can use to build an object from response" do
        user = BankApi::Data::User.from_hash(
          {
            name: "Kevin",
            status: "open",
            date_of_birth: '2021-01-01T00:00:00',
            account_ids: [1, 2, 3],
          },
        )

        expect(user.name).to eq("Kevin")
        expect(user.status).to eq("open")

        # Notice how the date of birth is converted to time object
        expect(user.date_of_birth).to be_kind_of(Time)
        expect(user.date_of_birth).to eq(Time.utc(2021, 1, 1, 0, 0, 0))

        expect(user.account_ids).to eq([1, 2, 3])
      end
    end
  end

  describe "#the-root" do
    let(:user_id) { 1 }
    let(:root) { BankApi::Root.new(id: user_id) }

    before do
      stub_alchemrest_request(root.build_request(:get_user))
        .to_return(
          status: 200,
          body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
        )

      stub_alchemrest_request(root.build_request(:get_transactions, account_id: 1))
        .to_return(
          status: 200,
          body: [
            FactoryBot.alchemrest_hash_for(
              :bank_api_transaction,
              amount_cents: 132_00,
              status: "completed",
              description: "Soda Pop",
            ),
            FactoryBot.alchemrest_hash_for(
              :bank_api_transaction,
              amount_cents: 155_00,
              status: "pending",
              description: "Carrots",
            ),
          ].to_json,
        )

      stub_alchemrest_request(root.build_request(:get_transactions, account_id: 2))
        .to_return(
          status: 200,
          body: [
            FactoryBot.alchemrest_hash_for(
              :bank_api_transaction,
              amount_cents: 100_00,
              status: "completed",
              description: "Popcorn",
            ),
            FactoryBot.alchemrest_hash_for(
              :bank_api_transaction,
              amount_cents: 120_00,
              status: "pending",
              description: "Licorce",
            ),
          ].to_json,
        )
    end

    describe "when we make requests from the root" do
      it "gets us the data" do
        transactions = root.get_transactions(account_id: 2).unwrap_or_raise!
        expect(transactions.size).to eq(2)
      end
    end

    describe "when we invoke our custom method on the root" do
      it "gets us the data" do
        transactions = root.all_transactions.unwrap_or_raise!
        expect(transactions.size).to eq(4)
      end
    end

    context 'when the api returns a handled error' do
      before do
        stub_alchemrest_request(root.build_request(:get_user))
          .to_return(
            status: 401,
          )
      end

      it "runs the error handler" do
        expect(Alchemrest.logger).to receive(:info).with('Credentials expired')
        root.all_transactions
      end
    end
  end
end
