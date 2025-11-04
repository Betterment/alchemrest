# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::Constraint::Block do
  let(:constraint_description) { "is foo" }
  subject do
    described_class.new(constraint_description) { |input| input == "foo" }
  end

  describe ".new" do
    context "with no block" do
      subject { described_class.new(constraint_description) }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "Must include a predicate block")
      end
    end
  end

  describe "#meets_conditions?" do
    context "when the input passes the predicate" do
      it "returns true" do
        expect(subject.meets_conditions?("foo")).to eq(true)
      end
    end

    context "when the input does not pass the predicate" do
      it "returns true" do
        expect(subject.meets_conditions?("bar")).to eq(false)
      end
    end
  end

  describe "#description" do
    it "uses the description" do
      expect(subject.description).to eq(constraint_description)
    end
  end
end
