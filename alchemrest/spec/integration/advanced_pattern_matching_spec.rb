# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/advanced_pattern_matching" do
  let(:root) { BankApi::Root.new(id: 1) }
  let(:result) { root.get_user }

  describe "#built-in-pattern-matching" do
    context "when using array based pattern matching" do
      subject do
        case result
          in Alchemrest::Result::Ok(value)
            value
          in Alchemrest::Result::Error(Alchemrest::ServerError)
            :server_error
          in Alchemrest::Result::Error(Alchemrest::ClientError => e)
            e.response.data
          else
            result.unwrap_or_rescue { nil }
        end
      end

      context "with a valid request matched by the first pattern" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 200,
              body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
            )
        end

        it "returns the actual user object" do
          expect(subject).to be_kind_of(BankApi::Data::User)
        end
      end

      context "with a server error matched by the second pattern" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 503,
            )
        end

        it "returns the actual user object" do
          expect(subject).to eq(:server_error)
        end
      end

      context "with a client error matched by the third pattern" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 404, body: { errors: ["Not found"] }.to_json,
            )
        end

        it "returns the actual user object" do
          expect(subject).to eq({ "errors" => ["Not found"] })
        end
      end
    end

    context "when using hash based pattern matching" do
      subject do
        case result
          in Alchemrest::Result::Ok(value:)
            value
          in Alchemrest::Result::Error(error: Alchemrest::ServerError)
            :server_error
          in Alchemrest::Result::Error(error: Alchemrest::ClientError => e)
            e.response.data
          else
            result.unwrap_or_rescue { nil }
        end
      end

      context "with a valid request matched by the first pattern" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 200,
              body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
            )
        end

        it "returns the actual user object" do
          expect(subject).to be_kind_of(BankApi::Data::User)
        end
      end

      context "with a server error matched by the second pattern" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 503,
            )
        end

        it "returns the actual user object" do
          expect(subject).to eq(:server_error)
        end
      end

      context "with a client error matched by the third pattern" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 404, body: { errors: ["Not found"] }.to_json,
            )
        end

        it "returns the actual user object" do
          expect(subject).to eq({ "errors" => ["Not found"] })
        end
      end
    end

    context "when pattern matching on the response data" do
      subject do
        case result
          in Alchemrest::Result::Ok
            :success
          in Alchemrest::Result::Error({ status: 422, error: { code: "001" }})
            :locked
          else
            result.unwrap_or_rescue { nil }
        end
      end

      context "with a request that has an error code of 001" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 422,
              body: { errors: { code: "001", description: "Locked" } }.to_json,
            )
        end

        it "matches the second pattern" do
          expect(subject).to eq(:locked)
        end
      end

      context "with a request that has an error code of 002" do
        let!(:api_request) do
          stub_alchemrest_request(root.build_request(:get_user))
            .to_return(
              status: 422,
              body: { errors: { code: "002", description: "Rejected" } }.to_json,
            )
        end

        it "matches no patterns" do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe "#exploring-alternative-patterns" do
    subject do
      case result
        in Alchemrest::Result::Ok(BankApi::Data::User => user)
          user
        in Alchemrest::Result::Ok[value]
          [:not_a_user, value]
        in { error: { status: 422 } }
          :locked
        else
          result.unwrap_or_rescue { nil }
      end
    end

    context "with a request that returns a user" do
      let!(:api_request) do
        stub_alchemrest_request(root.build_request(:get_user))
          .to_return(
            status: 200,
            body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
          )
      end

      it "matches the first pattern" do
        expect(subject).to be_kind_of(BankApi::Data::User)
      end
    end

    context "with a request that returns an empty array of tranasctions" do
      let!(:api_request) do
        stub_alchemrest_request(root.build_request(:get_transactions, account_id: 1))
          .to_return(
            status: 200,
            body: [].to_json,
          )
      end

      let(:result) { BankApi::Root.new(id: 1).get_transactions(account_id: 1) }

      it "matches the second pattern" do
        expect(subject).to eq [:not_a_user, []]
      end
    end

    context "with a client error with error code 001" do
      let!(:api_request) do
        stub_alchemrest_request(root.build_request(:get_user))
          .to_return(
            status: 422,
            body: { errors: { code: "001", description: "Locked" } }.to_json,
          )
      end

      it "matches the third pattern" do
        expect(subject).to eq :locked
      end
    end
  end
end
