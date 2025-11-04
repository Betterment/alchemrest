# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/custom_transformations" do
  let(:root) { BankApi::Root.new(id: 1) }
  let!(:api_request) do
    stub_alchemrest_request(root.build_request(:get_products))
      .to_return(
        status: 200,
        body: [
          FactoryBot.alchemrest_hash_for(
            :bank_api_product,
            interest_rate:,
            partner_revenue_rate:,
          ),
        ].to_json,
      )
  end
  let(:interest_rate) { "4.00%" }
  let(:partner_revenue_rate) { "0.0125" }

  let(:result) { BankApi::Root.new(id: 1).get_products }

  describe "#transformations_with_arguments" do
    context "with valid data" do
      it "returns the product with transformed data" do
        expect(result.unwrap_or_raise!.first.interest_rate).to be_a(BigDecimal)
        expect(result.unwrap_or_raise!.first.interest_rate).to eq(4.00)

        expect(result.unwrap_or_raise!.first.partner_revenue_rate).to be_a(BigDecimal)
        expect(result.unwrap_or_raise!.first.partner_revenue_rate).to eq(0.0125)
      end
    end

    context "with a non decimal value" do
      let(:interest_rate) { "" }

      it "raises a transform error" do
        expect { result.unwrap_or_raise! }.to raise_error Alchemrest::MorpherTransformError
      end
    end

    context "with a missing percent sign" do
      let(:interest_rate) { "4.00" }

      it "raises a transform error" do
        expect { result.unwrap_or_raise! }.to raise_error Alchemrest::MorpherTransformError
      end
    end

    context "with a negative value" do
      let(:interest_rate) { "-1.00%" }

      it "raises a transform error" do
        expect { result.unwrap_or_raise! }.to raise_error Alchemrest::MorpherTransformError
      end
    end
  end
end
