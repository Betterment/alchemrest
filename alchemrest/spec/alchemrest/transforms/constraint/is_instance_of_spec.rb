# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::Constraint::IsInstanceOf do
  subject { described_class.new(Integer) }

  describe "#meets_conditions?" do
    context "with an input that is an integer" do
      let(:input) { 5 }

      it { expect(subject.meets_conditions?(input)).to eq(true) }
    end

    context "with an input that is a float" do
      let(:input) { 5.5 }

      it { expect(subject.meets_conditions?(input)).to eq(false) }
    end
  end

  describe "#description" do
    it { expect(subject.description).to eq('is an Integer') }
  end
end
