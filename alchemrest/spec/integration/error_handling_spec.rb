# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/error_handling_patterns" do
  let(:user_id) { 1 }
  let(:root) { BankApi::Root.new(id: user_id) }

  context "when the request succeeds" do
    let!(:api_request) do
      stub_alchemrest_request(root.build_request(:get_user))
        .to_return(
          status: 200,
          body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
        )
    end

    it "executes our success code" do
      result = root.get_user

      name, error = case result
                      in Alchemrest::Result::Ok(user)
                        [user.name, nil]
                      in Alchemrest::Result::Error({status: 404})
                        [nil, "User not found"]
                      else
                        result.unwrap_or_rescue { [nil, "Uh Oh"] }
                    end

      expect(name).to eq("Kevin")
      expect(error).to eq(nil)
      expect(rescued_exceptions.count).to eq(0)
    end
  end

  context "when we get an error for a status code we are handling via pattern matching" do
    let!(:api_request) do
      stub_alchemrest_request(root.build_request(:get_user))
        .to_return(status: 404)
    end

    it "executes our error handling code and generates no alerts" do
      result = root.get_user

      name, error = case result
                      in Alchemrest::Result::Ok(data => user)
                        [user.name, nil]
                      in Alchemrest::Result::Error({status: 404})
                        [nil, "User not found"]
                      else
                        result.unwrap_or_rescue { [nil, "Uh Oh"] }
                    end

      expect(error).to eq("User not found")
      expect(name).to eq(nil)
      expect(rescued_exceptions.count).to eq(0)
    end
  end

  context "when we get an error code for a status code we only handle via unwrap_and_rescue" do
    let!(:api_request) do
      stub_alchemrest_request(root.build_request(:get_user))
        .to_return(status: 503)
    end

    it "executes our error handling code and has a rescued exception" do
      result = root.get_user

      name, error = case result
                      in Alchemrest::Result::Ok(data => user)
                        [user.name, nil]
                      in Alchemrest::Result::Error({status: 404})
                        [nil, "User not found"]
                      else
                        result.unwrap_or_rescue { [nil, "Uh Oh"] }
                    end

      expect(error).to eq("Uh Oh")
      expect(name).to eq(nil)
      expect(rescued_exceptions.count).to eq(1)
    end
  end

  context "when the api response includes error information in the body" do
    let!(:api_request) do
      stub_alchemrest_request(root.build_request(:post_transaction, account_id: 4, amount: 1000))
        .to_return(status: 422, body: { errors: { code: "001", description: "account_locked" } }.to_json)
    end

    it "allows us to extract the error and do special handling" do
      result = root.post_transaction(account_id: 4, amount: 1000)
      status = case result
                 in Alchemrest::Result::Ok(response)
                   :success
                 in Alchemrest::Result::Error({status: 422, error: {code: "001"}})
                   :locked
                 else
                   result.unwrap_or_raise!
               end

      expect(status).to eq(:locked)
    end

    context "when it's an error code we don't handle" do
      let!(:api_request) do
        stub_alchemrest_request(root.build_request(:post_transaction, account_id: 4, amount: 1000))
          .to_return(status: 422, body: { errors: { code: "002", description: "account_closed" } }.to_json)
      end

      it "raises " do
        result = root.post_transaction(account_id: 4, amount: 1000)

        expect {
          case result
            in Alchemrest::Result::Ok(response)
              :success
            in Alchemrest::Result::Error({status: 422, error: {code: "001"}})
              :locked
            else
              result.unwrap_or_raise!
          end
        }.to raise_error(Alchemrest::ClientError)
      end
    end
  end

  context "when we get a transformation error because of unexpected data in the response" do
    let!(:api_request) do
      stub_alchemrest_request(root.build_request(:get_user))
        .to_return(
          status: 200,
          body: { name: "Kevin", status: "frozen", date_of_birth: '2021-01-01T00:00:00', account_ids: [1, 2, 3] }.to_json,
        )
    end

    it "rescues the error" do
      result = root.get_user

      _name, error = case result
                       in Alchemrest::Result::Ok(user)
                         [user.name, nil]
                       in Alchemrest::Result::Error({status: 404})
                         [nil, "User not found"]
                       else
                         result.unwrap_or_rescue { [nil, "Uh Oh"] }
                     end

      expect(error).to eq("Uh Oh")
      expect(rescued_exceptions.count).to eq(1)
      expect(rescued_exceptions.first.cause).to be_a(Alchemrest::MorpherTransformError)
    end
  end

  context "when we're using the default logging behavior for rescued errors" do
    let!(:api_request) do
      stub_alchemrest_request(root.build_request(:get_user))
        .to_return(status: 404)
    end
    before { allow(Alchemrest.logger).to receive(:warn) }
    around do |example|
      AlchemrestIntegrationHelpers.disable_test_adapter
      example.run
      AlchemrestIntegrationHelpers.enable_test_adapter
    end

    it "logs useful output" do
      root.get_user.unwrap_or_rescue { "Uh Oh" }
      expect(Alchemrest.logger).to have_received(:warn).with("Alchemrest rescued an unexpected result of type Alchemrest::NotFoundError")
    end
  end
end
