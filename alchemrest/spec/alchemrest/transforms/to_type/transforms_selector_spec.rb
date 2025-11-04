# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::ToType::TransformsSelector do
  let(:from) { Alchemrest::Transforms::FromNumber.new }
  let(:to) { Money }
  let(:transform_options) do
    {
      cents: [Alchemrest::Transforms::MoneyTransform.new(:cents)],
      dollars: [Alchemrest::Transforms::MoneyTransform.new(:dollars)],
    }
  end

  subject { described_class.new(from, to, transform_options) }

  describe ".new" do
    context "with a valid transform options hash" do
      it "returns a new instance" do
        expect { subject }.not_to raise_error
      end
    end

    context "with non hash transform options" do
      let(:transform_options) { "foo" }

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError, described_class::INVALID_TRANSFORMS_HASH_ERROR_MESSAGE)
      end
    end

    context "with non symbol keys" do
      let(:transform_options) do
        {
          "cents" => [Alchemrest::Transforms::MoneyTransform.new(:cents)],
          dollars: [Alchemrest::Transforms::MoneyTransform.new(:dollars)],
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError, described_class::INVALID_TRANSFORMS_HASH_ERROR_MESSAGE)
      end
    end

    context "with non array values" do
      let(:transform_options) do
        {
          cents: Alchemrest::Transforms::MoneyTransform.new(:cents),
          dollars: [Alchemrest::Transforms::MoneyTransform.new(:dollars)],
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError, described_class::INVALID_TRANSFORMS_HASH_ERROR_MESSAGE)
      end
    end

    context "with non transform values" do
      let(:transform_options) do
        {
          cents: ["foo", Alchemrest::Transforms::MoneyTransform.new(:cents)],
          dollars: [Alchemrest::Transforms::MoneyTransform.new(:dollars)],
        }
      end

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError, described_class::INVALID_TRANSFORMS_HASH_ERROR_MESSAGE)
      end
    end
  end

  describe "#options" do
    it "returns the keys of the transform options" do
      expect(subject.options).to contain_exactly(:cents, :dollars)
    end
  end

  describe "#using" do
    context "when the argument is a `Morpher::Transform`" do
      let(:transform) { Morpher::Transform::Block.capture("euros") { |input| Morpher::Either::Right.new(Money.from_cents(input, "EUR")) } }

      it "delegates to the `to` transform" do
        result = subject.using(transform)
        expect(result.use.sole.name).to eq("euros")
        expect(result.call(10_00).from_right).to eq(Money.from_cents(10_00, "EUR"))
      end
    end

    context "when the argument is a key of the transform options hash" do
      it "returns a new `ToType` transform using the value of that key" do
        result = subject.using(:cents)
        expect(result.use.sole).to be_a(Alchemrest::Transforms::MoneyTransform)
        expect(result.call(10_00).from_right).to eq(Money.from_cents(10_00))
      end
    end

    context "when the argument is not a key of our transform options" do
      it "raises an error" do
        expected = "No transform named foo for Number -> Money. Available options: cents, dollars"
        expect { subject.using(:foo) }.to raise_error(Alchemrest::NoTransformOptionForNameError, expected)
      end
    end

    context "when the argument is neither a symbol or transform" do
      it "raises an error" do
        expect { subject.using(1) }.to raise_error(ArgumentError, "Must provide a symbol key or a Morpher::Transform")
      end
    end
  end
end
