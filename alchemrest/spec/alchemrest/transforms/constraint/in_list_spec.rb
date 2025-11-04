# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::Constraint::InList do
  subject { described_class.new(%w(foo bar baz)) }

  describe "#meets_conditions?" do
    context "with an input in the list" do
      let(:input) { "foo" }

      it "returns true" do
        expect(subject.meets_conditions?(input)).to eq(true)
      end
    end

    context "with an input not in the list" do
      let(:input) { "qux" }

      it "returns false" do
        expect(subject.meets_conditions?(input)).to eq(false)
      end
    end
  end

  describe "#description" do
    it "returns the description" do
      expect(subject.description).to eq('in list ["foo", "bar", "baz"]')
    end
  end
end
