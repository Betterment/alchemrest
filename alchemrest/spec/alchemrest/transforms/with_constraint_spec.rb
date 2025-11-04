# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::WithConstraint do
  let(:constraint) { Alchemrest::Transforms::Constraint::Block.new("is not nil") { |input| !input.nil? } }

  subject { described_class.new(constraint) }

  describe "#call" do
    context "when the input meets the constraint conditions" do
      let(:input) { "foo" }

      it "returns a prelude wrapping the input" do
        expect(subject.call(input).from_right).to eq(input)
      end
    end

    context "when the input does not meet the constraint conditions" do
      let(:input) { "foo" }
      let(:constraint) { Alchemrest::Transforms::Constraint::Block.new("is not foo") { |input| input != "foo" } }

      it "returns a prelude wrapping an error" do
        error = subject.call(input).from_left
        expect(error).to be_a(Morpher::Transform::Error)
        expect(error.message).to eq(%(Input "foo" does not meet the constraint "is not foo"))
        expect(error.input).to eq(input)
      end
    end
  end

  describe ".new" do
    context "when the constraint is not an instance of Alchemrest::Transforms::Constraint" do
      it "raises an ArgumentError" do
        expect { described_class.new("foo") }.to raise_error(ArgumentError, "Must provide an instance of Alchemrest::Transform::Constraint")
      end
    end

    context "with a valid constraint" do
      subject { described_class.new(constraint) }

      it "does not raise an error and sets constraint" do
        expect { subject }.not_to raise_error
      end
    end
  end
end
