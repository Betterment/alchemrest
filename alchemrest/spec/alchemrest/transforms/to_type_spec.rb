# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::ToType do
  subject do
    described_class.using(from:, to: Integer, constraints:) { |input| input.to_i }
  end

  it_behaves_like "constrainable", predicate: ->(input) { input < 10 }, passing_input: "9", failing_input: "11"

  let(:from) { Alchemrest::Transforms::FromType.new(type: String) }
  let(:constraints) { [] }

  describe ".new" do
    context "when we use an subclass of FromType" do
      let(:from) { Alchemrest::Transforms::FromString.new }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when the from argument is not an instance of Alchemrest::Transforms::FromType" do
      it "raises an ArgumentError" do
        expect { described_class.new(from: "foo", to: Integer, use: [Morpher::Transform::Success.new(->(input) { input.to_i })]) }
          .to raise_error(ArgumentError, ":from must be a FromType transform")
      end

      context "when the to argument is not a type" do
        it "raises an ArgumentError" do
          expect { described_class.new(from:, to: "foo", use: [Morpher::Transform::Success.new(->(input) { input.to_i })]) }
            .to raise_error(ArgumentError, ":to must be a Class")
        end
      end

      context "when the use argument is not an array" do
        it "raises an ArgumentError" do
          expect { described_class.new(from:, to: Integer, use: "foo") }
            .to raise_error(ArgumentError, ":use must be an array of Morpher::Transform instances")
        end
      end

      context "when the use argument is an empty array" do
        it "raises an ArgumentError" do
          expect { described_class.new(from:, to: Integer, use: []) }
            .to raise_error(ArgumentError, ":use must be an array of Morpher::Transform instances")
        end
      end

      context "when the use argument is an array of things besides transforms" do
        it "raises an ArgumentError" do
          expect { described_class.new(from:, to: Integer, use: [1, Morpher::Transform::Success.new(->(input) { input.to_i })]) }
            .to raise_error(ArgumentError, ":use must be an array of Morpher::Transform instances")
        end
      end
    end
  end

  describe "#output_type" do
    it "matches the to type" do
      expect(subject.output_type).to eq(Alchemrest::Transforms::OutputType.simple(Integer))
    end
  end

  describe "#call" do
    context "with a simple unconstriained from transform" do
      let(:from) { Alchemrest::Transforms::FromType.new(type: String) }

      context "when the input matches the from type" do
        let(:input) { "10" }
        it "successfully transforms the input using the block" do
          expect(subject.call(input).from_right).to eq(10)
        end
      end

      context "when the input does not match the from type" do
        let(:input) { 10 }

        it "returns an error" do
          error = subject.call(input)

          expect(error.left?).to eq(true)
          expect(error.from_left.compact_message).to match("Expected: String but got: Integer")
        end
      end

      context "when the output does not match the to type" do
        subject do
          described_class.using(from:, to: Integer, constraints:) { |input| input }
        end
        let(:input) { "10" }

        it "returns an error" do
          error = subject.call(input)

          expect(error.left?).to eq(true)

          expect(error.from_left.compact_message)
            .to match("Alchemrest::Transform::ToType: Transform chain created an ouput of type: String. Expected: Integer")

          expect(error.from_left.input).to eq(input)
        end
      end

      context "when the output is a sub class of type" do
        subject do
          described_class.using(from:, to: Numeric, constraints:) { |input| input.to_i.to_f }
        end

        let(:input) { "10" }

        it "returns an error" do
          expect(subject.call(input).from_right).to eq(10.0)
        end
      end

      context "when constraints is not provided" do
        subject do
          described_class.using(from:, to: Integer) { |input| input.to_i }
        end

        it "calls does not error" do
          expect { subject.call("10") }.not_to raise_error
        end
      end
    end

    context "with a from transform with multiple constraints" do
      let(:from) do
        Alchemrest::Transforms::FromType.new(type: String)
          .where("matches integer regex") { |input| input.match? /\A\d+\z/ }
          .where("has no leading zeros") { |input| !input.start_with?("0") }
      end

      context "when the input passes all constraints" do
        let(:input) { "10" }

        it "returns the transformed output" do
          expect(subject.call(input).from_right).to eq(10)
        end
      end

      context "when the input does not pass all constraints" do
        let(:input) { "010" }

        it "returns an error" do
          error = subject.call(input)

          expect(error.left?).to eq(true)
          expect(error.from_left.compact_message).to match(%(Input "010" does not meet the constraint "has no leading zeros"))
          expect(error.from_left.input).to eq(input)
        end
      end
    end
  end

  describe "#all_constraints" do
    let(:from) do
      Alchemrest::Transforms::FromType.new(type: String)
        .where("matches integer regex") { |input| input.match? /\A\d+\z/ }
        .where("has no leading zeros") { |input| !input.start_with?("0") }
    end

    subject do
      described_class.using(from:, to: Integer, constraints:) { |input| input.to_i }
        .where("less than 10") { |input| input < 10 }
    end

    it "returns all constraints" do
      expect(subject.all_constraints).to contain_exactly(
        have_attributes(description: "matches integer regex"),
        have_attributes(description: "has no leading zeros"),
        have_attributes(description: "less than 10"),
      )
    end
  end

  describe "#constraints_for" do
    let(:from) do
      Alchemrest::Transforms::FromType.new(type: String)
        .where("matches integer regex") { |input| input.match? /\A\d+\z/ }
        .where("has no leading zeros") { |input| !input.start_with?("0") }
    end

    subject do
      described_class.using(from:, to: Integer, constraints:) { |input| input.to_i }
        .where("less than 10") { |input| input < 10 }
    end

    context "with for as the to type" do
      it "returns only constraints defined after the to transform" do
        expect(subject.constraints_for(Integer)).to contain_exactly(
          have_attributes(description: "less than 10"),
        )
      end
    end

    context "with for as the from type" do
      it "returns only constrains defined before the to transform" do
        expect(subject.constraints_for(String)).to contain_exactly(
          have_attributes(description: "matches integer regex"),
          have_attributes(description: "has no leading zeros"),
        )
      end
    end

    context "with a type that's not part of the transformation chain" do
      it "raises an argument error" do
        expect { subject.constraints_for(Array) }
          .to raise_error ArgumentError, "`type` must be either the to type (Integer) or the from type (String), was Array"
      end
    end

    context "with an arguments that's not a type" do
      it "raises an argument error" do
        expect { subject.constraints_for("foo") }.to raise_error ArgumentError, "Must provide a Class"
      end
    end
  end

  describe "#using" do
    it "returns a new transform with use set" do
      new_transform = subject.using([Morpher::Transform::Block.capture("negative") { |input| -input }])
      expect(new_transform.use.sole.name).to eq("negative")
    end
  end

  describe "array" do
    it "returns a typed collection transform" do
      transform = subject.array

      expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.simple(T::Array[Integer])
      expect(transform.call(["10"]).from_right).to eq([10])
    end

    context "when we have constraints on both the from and the to" do
      let(:from) do
        Alchemrest::Transforms::FromType.new(type: String)
          .where("matches integer regex") { |input| input.match? /\A\d+\z/ }
          .where("has no leading zeros") { |input| !input.start_with?("0") }
      end

      subject do
        described_class.using(from:, to: Integer, constraints:) { |input| input.to_i }
          .where("less than 10") { |input| input < 10 }
      end

      it "includes all the constraints on the output type" do
        expect(subject.array.output_type)
          .to eq Alchemrest::Transforms::OutputType.new(sorbet_type: T::Array[Integer], constraints: from.constraints + subject.constraints)
      end
    end
  end

  describe "maybe" do
    it "returns a typed nilable transform" do
      transform = subject.maybe

      expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.simple(T.nilable(Integer))
      expect(transform.call(nil).from_right).to eq(nil)
      expect(transform.call("10").from_right).to eq(10)
    end

    context "when we have constraints on both the from and the to" do
      let(:from) do
        Alchemrest::Transforms::FromType.new(type: String)
          .where("matches integer regex") { |input| input.match? /\A\d+\z/ }
          .where("has no leading zeros") { |input| !input.start_with?("0") }
      end

      subject do
        described_class.using(from:, to: Integer, constraints:) { |input| input.to_i }
          .where("less than 10") { |input| input < 10 }
      end

      it "includes all the constraints on the output type" do
        expect(subject.maybe.output_type)
          .to eq Alchemrest::Transforms::OutputType.new(sorbet_type: T.nilable(Integer),
            constraints: from.constraints + subject.constraints)
      end
    end
  end
end
