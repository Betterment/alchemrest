# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/chainable_transforms" do
  describe "#chainable-transforms" do
    subject { BankApi::Requests::GetProducts.new }

    let(:data) do
      FactoryBot.alchemrest_hash_for(
        :bank_api_product,
      )
    end

    let!(:api_request) do
      stub_alchemrest_request(subject)
        .to_return(
          status: 200,
          body: [data].to_json,
        )
    end

    let(:root) { BankApi::Root.new(id: 1) }

    it "loads the product data from the example" do
      product = root.get_products.unwrap_or_raise!.first
      expect(product).to be_a(BankApi::Data::Product)
      expect(product.partner_revenue_rate).to eq(BigDecimal('0.0125'))
    end
  end

  describe "#block-constraints" do
    subject { Alchemrest::Transforms.from.string.where("is palindrome") { |input| input.reverse == input } }

    it "handles inputs correctly" do
      expect(subject.call("apple").left?).to be(true)
      expect(subject.call("racecar").right?).to be(true)
    end
  end

  describe "#custom-constraints" do
    before do
      is_palindrome = Class.new(Alchemrest::Transforms::Constraint) do
        def description
          "is palindrome"
        end

        def meets_conditions?(input)
          input.reverse == input
        end
      end

      stub_const("IsPalindrome", is_palindrome)
    end

    subject { Alchemrest::Transforms.from.string.where(IsPalindrome.new) }

    it "handles inputs correctly" do
      expect(subject.call("apple").left?).to be(true)
      expect(subject.call("racecar").right?).to be(true)
    end
  end

  describe "#block-transformations" do
    before do
      financial_institution = Class.new do
        attr_reader :key

        def self.keys
          %i(acme_bank gringotts the_iron_bank)
        end

        def self.from_key(key)
          new(key)
        end

        def initialize(key)
          @key = key
        end

        def ==(other)
          key == other.key
        end
      end

      stub_const("FinancialInstitution", financial_institution)
    end

    subject do
      Alchemrest::Transforms.from.string
        .where.in(FinancialInstitution.keys.map(&:to_s))
        .to(FinancialInstitution) { |input| FinancialInstitution.from_key(input.to_sym) }
    end

    it "runs the block transformation" do
      expect(subject.call("the_iron_bank").from_right).to eq(FinancialInstitution.new(:the_iron_bank))
    end
  end
end
