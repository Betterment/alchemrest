# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::Union do
  subject { described_class.new(types:, discriminator:) }

  let(:types) do
    {
      check: BankApi::Data::Check,
      card: BankApi::Data::Card,
      ach: BankApi::Data::Ach,
    }
  end

  let(:discriminator) { :source_type }

  describe "#output_type" do
    it "returns a union type of the types" do
      expect(subject.output_type.sorbet_type).to eq(T.any(BankApi::Data::Check, BankApi::Data::Card, BankApi::Data::Ach))
    end
  end
end
