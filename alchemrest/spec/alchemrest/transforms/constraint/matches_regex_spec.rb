# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::Constraint::MatchesRegex do
  subject { described_class.new(/\A\d{5}\z/) }

  describe "#meets_conditions?" do
    context "with a valid input" do
      let(:input) { "12345" }

      it "returns true" do
        expect(subject.meets_conditions?(input)).to eq(true)
      end
    end

    context "with an invalid input" do
      let(:input) { "abcde" }

      it "returns false" do
        expect(subject.meets_conditions?(input)).to eq(false)
      end
    end
  end

  describe "#description" do
    it "returns the description" do
      expect(subject.description).to eq("matches /\\A\\d{5}\\z/")
    end
  end
end
