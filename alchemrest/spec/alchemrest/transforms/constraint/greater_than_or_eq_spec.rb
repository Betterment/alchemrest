# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::Constraint::GreaterThanOrEq do
  subject { described_class.new(5) }

  describe "#meets_conditions?" do
    context "with an input that equals the value" do
      let(:input) { 5 }

      it { expect(subject.meets_conditions?(input)).to eq(true) }
    end

    context "with an input less than the value" do
      let(:input) { 4 }

      it { expect(subject.meets_conditions?(input)).to eq(false) }
    end

    context "with an input greater than the value" do
      let(:input) { 6 }

      it { expect(subject.meets_conditions?(input)).to eq(true) }
    end
  end

  describe "#description" do
    it { expect(subject.description).to eq('greater than or equal to 5') }
  end
end
