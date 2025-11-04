# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'docs/capturing_responses_for_debugging.md' do
  let(:root) { BankApi::Root.new(id: 1) }

  let!(:api_request) do
    stub_alchemrest_request(root.build_request(:get_user))
      .to_return(
        status: 200,
        body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
      )
  end

  describe "#configuring-where-captured-responses-go" do
    context "when a block is given to `Alchemrest.on_response_captured`" do
      let(:captured_requests) { [] }

      around do |example|
        Alchemrest.on_response_captured do |identifier:, result:|
          captured_requests << [identifier, result.unwrap_or_raise!]
        end
        example.run
        AlchemrestIntegrationHelpers.enable_test_adapter
      end

      it "uses that block for the response capture pipeline" do
        expect { root.get_user(id: 1) }.to change { captured_requests.count }.by(1)
        expect(captured_requests.first)
          .to eq(
            ["GET /api/v1/users/1?includeDetails=true",
             { name: "Kevin", status: "open", date_of_birth: "2021-01-01T00:00:00", account_ids: [1, 2] }],
          )
      end
    end
  end

  describe "#configuring-whats-captured" do
    around do |example|
      original = Alchemrest.filter_parameters
      Alchemrest.filter_parameters += %i(account_id settled_at)
      example.run
      Alchemrest.filter_parameters = original
    end

    context "with a class that has a `configure_response_capture` block" do
      before do
        stub_alchemrest_request(root.build_request(:get_transactions, account_id: 1))
          .to_return(
            status: 200,
            body: [FactoryBot.alchemrest_hash_for(:bank_api_transaction)].to_json,
          )

        stub_alchemrest_request(root.build_request(:get_transactions, account_id: 2))
          .to_return(
            status: 200,
            body: [FactoryBot.alchemrest_hash_for(:bank_api_transaction)].to_json,
          )
      end

      it "properly omits and unsanitizes the data as configured" do
        root.all_transactions.unwrap_or_raise!
        expect(captured_responses.count).to eq(3)

        expect(captured_responses[1][:data][0]).to include({ settled_at: "[FILTERED]", account_id: "123456789" })
        expect(captured_responses[1][:data][0]).not_to include({ description: anything })
      end
    end
  end
end
