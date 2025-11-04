# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::FromString do
  let(:constraints) { [] }
  subject { described_class.new(constraints:) }

  it_behaves_like "constrainable", predicate: ->(input) { input.start_with?("a") }, passing_input: "apple", failing_input: "orange"

  describe ".new" do
    subject { described_class.new }

    it "builds a callable transform" do
      expect(subject.call("foo").from_right).to eq("foo")
    end
  end

  describe "#output_type" do
    it "is string" do
      expect(subject.output_type).to eq(Alchemrest::Transforms::OutputType.simple(String))
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
        output = subject.where("starts with a") { |input| input.start_with?("a") }
        expect(output.constraints.first.description).to eq("starts with a")
        expect(output.call("apple").right?).to eq(true)
        expect(output.call("organe").left?).to eq(true)
      end
    end

    context "with only a block" do
      it "returns a properly constrainted transform" do
        expect { subject.where { |input| input.start_with?("a") } }
          .to raise_error(ArgumentError, "Must provide a constraint or description")
      end
    end

    context "when chaining multiple constraints" do
      it "returns a properly constrainted transform" do
        expect(subject.where.min_length(3).max_length(5).constraints)
          .to contain_exactly(
            Alchemrest::Transforms::Constraint::MinLength.new(3),
            Alchemrest::Transforms::Constraint::MaxLength.new(5),
          )
      end
    end

    context "when the from string transform has existing constraints" do
      subject { described_class.new(constraints: [Alchemrest::Transforms::Constraint::MaxLength.new(3)]) }

      it "returns a maintains those constrains across chained calls" do
        expect(subject.where.min_length(3).constraints)
          .to contain_exactly(
            Alchemrest::Transforms::Constraint::MaxLength.new(3),
            Alchemrest::Transforms::Constraint::MinLength.new(3),
          )
      end
    end
  end

  describe "#to" do
    context "to Time" do
      it "returns a time object" do
        expected = ActiveSupport::TimeZone.new("Eastern Time (US & Canada)").parse('Thursday, September 8, 2022 2:57:22.99999 PM')
        expect(subject.to(Time).using(:utc).call("2022-09-08T14:57:22.99999-04:00").from_right).to eq(expected)
      end
    end

    context "to Date" do
      it "returns a Date object" do
        expect(subject.to(Date).call("2022-01-01").from_right).to eq(Date.new(2022, 1, 1))
      end
    end
  end
end
