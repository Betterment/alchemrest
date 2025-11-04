# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::ToDecimal do
  subject { described_class.new }

  describe "#call" do
    context "when the input is number string" do
      let(:input) { "123" }

      it "returns a big decimal" do
        expect(subject.call(input).from_right).to eq(BigDecimal(input))
      end
    end

    context "when the input is an invalid string" do
      let(:input) { "abc" }
      let(:error) do
        Morpher::Transform::Error.new(
          cause: nil,
          input:,
          transform: subject,
          message: "Expected #{input} to be castable to BigDecimal",
        )
      end

      it "returns an error" do
        expect(subject.call(input).from_left).to eq(error)
      end
    end

    context "when the input is an integer" do
      let(:input) { 10 }

      it "returns an a big decimal" do
        expect(subject.call(input).from_right).to eq(BigDecimal('10'))
      end
    end

    context "when the input is a float" do
      let(:input) { 10.25 }

      it "returns a big decimal" do
        expect(subject.call(input).from_right).to eq(BigDecimal('10.25', 0))
      end
    end

    context "when the input is a rational" do
      let(:input) { Rational(10, 2) }

      it "returns a big decimal" do
        expect(subject.call(input).from_right).to eq(BigDecimal('5'))
      end
    end

    context "when the input is a big decimal" do
      let(:input) { BigDecimal('10.25', 0) }

      it "returns a big decimal" do
        expect(subject.call(input).from_right).to eq(BigDecimal('10.25', 0))
      end
    end
  end
end
