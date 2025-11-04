# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::FromNumber do
  let(:constraints) { [] }
  subject { described_class.new(constraints:) }

  it_behaves_like "constrainable", predicate: ->(input) { input > 0 }, passing_input: 1, failing_input: 0

  describe ".new" do
    subject { described_class.new }

    it "builds a callable transform" do
      expect(subject.call(10).from_right).to eq(10)
    end
  end

  describe "#call" do
    context "with a Float" do
      it "returns the input" do
        expect(subject.call(10.25).from_right).to eq(10.25)
      end
    end

    context "with an Integer" do
      it "returns the input" do
        expect(subject.call(10).from_right).to eq(10)
      end
    end

    context "with a BigDecimal" do
      it "returns an error" do
        expect(subject.call(BigDecimal("10.25")).left?).to be(true)
      end
    end
  end

  describe "#output_type" do
    it "is a union of Integer and Float" do
      expect(subject.output_type).to eq(Alchemrest::Transforms::OutputType.simple(T.any(Integer, Float)))
    end
  end

  describe "#where" do
    context "with no arguments" do
      it "returns self" do
        expect(subject.where).to eq(subject)
      end
    end

    context "with a block and description" do
      it "returns a properly constrainted transform" do
        output = subject.where("a whole number") { |input| input.to_i == input }
        expect(output.constraints.first.description).to eq("a whole number")
        expect(output.call(5.0).right?).to eq(true)
        expect(output.call(5.5).left?).to eq(true)
      end
    end

    context "with only a block" do
      it "returns a properly constrainted transform" do
        expect { subject.where { |input| input.to_i == input } }
          .to raise_error(ArgumentError, "Must provide a constraint or description")
      end
    end

    context "when chaining multiple constraints" do
      it "returns a properly constrainted transform" do
        expect(subject.where.greater_than(3).less_than(5).constraints)
          .to contain_exactly(
            Alchemrest::Transforms::Constraint::GreaterThan.new(3),
            Alchemrest::Transforms::Constraint::LessThan.new(5),
          )
      end
    end

    context "when the from number transform has existing constraints" do
      subject { described_class.new(constraints: [Alchemrest::Transforms::Constraint::GreaterThan.new(3)]) }

      it "maintains those constrains across chained calls" do
        expect(subject.where.less_than(5).constraints)
          .to contain_exactly(
            Alchemrest::Transforms::Constraint::GreaterThan.new(3),
            Alchemrest::Transforms::Constraint::LessThan.new(5),
          )
      end
    end
  end

  describe "#output_type_number" do
    it "is Number" do
      expect(subject.output_type_name).to be("Number")
    end
  end

  describe "#to" do
    context "to Money using :cents" do
      it "returns a Money object" do
        expect(subject.to(Money).using(:cents).call(10_00).from_right).to eq(Money.from_cents(10_00))
      end
    end

    context "to Money using :dollars" do
      it "returns a Money object" do
        expect(subject.to(Money).using(:dollars).call(10).from_right).to eq(Money.from_cents(10_00))
      end
    end
  end
end
