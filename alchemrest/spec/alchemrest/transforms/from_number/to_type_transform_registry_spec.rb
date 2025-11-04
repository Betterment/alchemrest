# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::FromNumber::ToTypeTransformRegistry do
  let(:from) { Alchemrest::Transforms::FromNumber.new }
  subject { described_class.new(from) }

  describe "#resolve" do
    context "with Money" do
      it "returns a selector" do
        expect(subject.resolve(Money)).to be_a(Alchemrest::Transforms::ToType::TransformsSelector)
        expect(subject.resolve(Money).options).to eq(%i(cents dollars))
        expect(subject.resolve(Money).using(:cents).call(100).from_right).to eq(Money.from_amount(1))
        expect(subject.resolve(Money).using(:dollars).call(100).from_right).to eq(Money.from_amount(100))
      end
    end

    context "with an unregistered type" do
      it "raises an error" do
        expect {
          subject.resolve(Symbol)
        }.to raise_error(Alchemrest::NoRegisteredTransformError, "No registered transform for Number -> Symbol")
      end
    end
  end
end
