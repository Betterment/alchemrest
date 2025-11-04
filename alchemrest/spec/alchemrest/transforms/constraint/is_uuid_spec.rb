# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::Constraint::IsUuid do
  describe "#meets_conditions?" do
    context "with a valid input" do
      let(:input) { SecureRandom.uuid }

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
      expect(subject.description).to eq("is a UUID string")
    end
  end
end
