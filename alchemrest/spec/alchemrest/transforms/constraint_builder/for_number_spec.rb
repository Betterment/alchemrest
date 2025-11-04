# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::ConstraintBuilder::ForNumber do
  let(:constrainable) { Alchemrest::Transforms::FromNumber.new }
  subject { described_class.new(constrainable) }

  describe "#greater_than" do
    it "adds a GreaterThan constraint to the constrainable" do
      expect(subject.greater_than(3)).to be_a(Alchemrest::Transforms::FromNumber)
      expect(subject.greater_than(3).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::GreaterThan.new(3))
    end
  end

  describe "#greater_than_or_eq" do
    it "adds a GreaterThanOrEq constraint to the constrainable" do
      expect(subject.greater_than_or_eq(3)).to be_a(Alchemrest::Transforms::FromNumber)
      expect(subject.greater_than_or_eq(3).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::GreaterThanOrEq.new(3))
    end
  end

  describe "#less_than" do
    it "adds a LessThan constraint to the constrainable" do
      expect(subject.less_than(3)).to be_a(Alchemrest::Transforms::FromNumber)
      expect(subject.less_than(3).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::LessThan.new(3))
    end
  end

  describe "#less_than_or_eq_to" do
    it "adds a LessThanOrEq constraint to the constrainable" do
      expect(subject.less_than_or_eq(3)).to be_a(Alchemrest::Transforms::FromNumber)
      expect(subject.less_than_or_eq(3).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::LessThanOrEq.new(3))
    end
  end

  describe "#positive" do
    it "addes a GreaterThan(0) constraint to the constrainable" do
      expect(subject.positive).to be_a(Alchemrest::Transforms::FromNumber)
      expect(subject.positive.constraints).to contain_exactly(Alchemrest::Transforms::Constraint::GreaterThan.new(0))
    end
  end

  describe "#non_negative" do
    it "addes a GreaterThanOrEq(0) constraint to the constrainable" do
      expect(subject.non_negative).to be_a(Alchemrest::Transforms::FromNumber)
      expect(subject.non_negative.constraints).to contain_exactly(Alchemrest::Transforms::Constraint::GreaterThanOrEq.new(0))
    end
  end

  describe "#integer" do
    it "addes a IsInteger constraint to the constrainable" do
      expect(subject.integer).to be_a(Alchemrest::Transforms::FromNumber)
      expect(subject.integer.constraints).to contain_exactly(Alchemrest::Transforms::Constraint::IsInstanceOf.new(Integer))
    end
  end
end
