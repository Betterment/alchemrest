# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::JsonNumber do
  subject { described_class.new }

  describe "#call" do
    context "with a integer input" do
      it "returns the input" do
        expect(subject.call(1).from_right).to eq(1)
      end
    end

    context "with a float input" do
      it "returns the input" do
        expect(subject.call(1.1).from_right).to eq(1.1)
      end
    end

    context "with a string input" do
      it "returns an error" do
        error = Morpher::Transform::Error.new(
          cause: nil,
          input: "foo",
          transform: subject,
          message: "Expected: Float, Integer but got String",
        )
        expect(subject.call("foo").from_left).to eq(error)
      end
    end

    context "with a BigDecimal input" do
      it "returns an error" do
        error = Morpher::Transform::Error.new(
          cause: nil,
          input: BigDecimal('1'),
          transform: subject,
          message: "Expected: Float, Integer but got BigDecimal",
        )
        expect(subject.call(BigDecimal('1')).from_left).to eq(error)
      end
    end
  end
end
