# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::Constraint::MinLength do
  subject { described_class.new(5) }

  describe "#meets_conditions?" do
    context "with an input exactly 5 characters" do
      let(:input) { "12345" }

      it "returns true" do
        expect(subject.meets_conditions?(input)).to eq(true)
      end
    end

    context "with an input more than 5 characters" do
      let(:input) { "123456" }

      it "returns true" do
        expect(subject.meets_conditions?(input)).to eq(true)
      end
    end

    context "with an input less than 5 characters input" do
      let(:input) { "1234" }

      it "returns false" do
        expect(subject.meets_conditions?(input)).to eq(false)
      end
    end
  end

  describe "#description" do
    it "returns the description" do
      expect(subject.description).to eq("min length of 5")
    end
  end
end
