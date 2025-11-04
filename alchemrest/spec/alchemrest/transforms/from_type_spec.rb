# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::FromType, squad: :employee_wellness do
  subject { described_class.new(type: String, constraints:) }

  it_behaves_like "constrainable", predicate: ->(input) { input.start_with?("a") }, passing_input: "apple", failing_input: "orange"

  let(:constraints) { [] }

  describe "#call" do
    context "when the input matches the type" do
      let(:input) { "foo" }

      context "with no constraints" do
        let(:constraints) { [] }

        it "returns the input" do
          expect(subject.call(input).from_right).to eq(input)
        end
      end

      context "with a single passing constraint" do
        let(:constraints) do
          [
            Alchemrest::Transforms::Constraint::Block.new(:starts_with_f) { |input| input.start_with?("f") },
          ]
        end

        it "returns the input" do
          expect(subject.call(input).from_right).to eq(input)
        end
      end

      context "with multiple passing constraints" do
        let(:constraints) do
          [
            Alchemrest::Transforms::Constraint::Block.new("starts with f") { |input| input.start_with?("f") },
            Alchemrest::Transforms::Constraint::Block.new("starts_with o") { |input| input.end_with?("o") },
          ]
        end

        it "returns the input" do
          expect(subject.call(input).from_right).to eq(input)
        end
      end

      context "with a single failing constraint" do
        let(:constraints) do
          [
            Alchemrest::Transforms::Constraint::Block.new("starts with a") { |input| input.start_with?("a") },
          ]
        end

        it "returns an Error class" do
          error = subject.call(input).from_left
          expect(error).to be_a(Morpher::Transform::Error)
          expect(error.compact_message).to match(/does not meet the constraint "starts with a"/)
          expect(error.input).to eq(input)
        end
      end

      context "with one passing constraint and one failing constraint" do
        let(:constraints) do
          [
            Alchemrest::Transforms::Constraint::Block.new("starts with f") { |input| input.start_with?("f") },
            Alchemrest::Transforms::Constraint::Block.new("ends with s") { |input| input.end_with?("s") },
          ]
        end

        it "returns an error" do
          error = subject.call(input).from_left
          expect(error).to be_a(Morpher::Transform::Error)
          expect(error.compact_message).to match(/does not meet the constraint "ends with s"/)
          expect(error.input).to eq(input)
        end
      end

      context "with constraints not provided" do
        subject { described_class.new(type: String) }

        it "returns the input" do
          expect(subject.call(input).from_right).to eq(input)
        end
      end
    end

    context "when the input does not match the type" do
      let(:input) { 10 }

      it "returns an error" do
        error = subject.call(input).from_left
        expect(error).to be_a(Morpher::Transform::Error)
        expect(error.compact_message).to match(/Expected: String but got: Integer/)
        expect(error.input).to eq(input)
      end
    end
  end

  describe "array" do
    it "returns a typed collection transform" do
      transform = subject.array

      expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.simple(T::Array[String])
      expect(transform.call(["foo"]).from_right).to eq(["foo"])
    end

    context "when we have constraints" do
      let(:constraints) { [Alchemrest::Transforms::Constraint::MaxLength.new(10)] }

      it "includes those constraints in the type" do
        transform = subject.array

        expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.new(sorbet_type: T::Array[String], constraints:)
        expect(transform.call(["foo"]).from_right).to eq(["foo"])
      end
    end
  end

  describe "maybe" do
    it "returns a typed nilable transform" do
      transform = subject.maybe

      expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.simple(T.nilable(String))
      expect(transform.call(nil).from_right).to eq(nil)
      expect(transform.call("test").from_right).to eq("test")
    end

    context "when we have constraints" do
      let(:constraints) { [Alchemrest::Transforms::Constraint::MaxLength.new(10)] }

      it "includes those constraints in the type" do
        transform = subject.maybe

        expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.new(sorbet_type: T.nilable(String), constraints:)
        expect(transform.call(nil).from_right).to eq(nil)
        expect(transform.call("test").from_right).to eq("test")
      end
    end
  end

  describe "#constraints" do
    it "defaults to an empty array" do
      expect(subject.constraints).to be_empty
    end
  end

  describe "#output_type" do
    it "matches the type provided to initialize" do
      expect(subject.output_type).to eq(Alchemrest::Transforms::OutputType.simple(String))
    end
  end

  describe "#output_type_name" do
    it "matches the name type provided to initialize" do
      expect(subject.output_type_name).to eq("String")
    end
  end

  describe "#to" do
    context "with a block" do
      it "returns a new transform with the right output type and behavior" do
        output = subject.to(Integer) { |input| input.to_i }
        expect(output).to be_a(Alchemrest::Transforms::ToType)
        expect(output.output_type).to eq(Alchemrest::Transforms::OutputType.simple(Integer))
        expect(output.call("10").from_right).to eq(10)
        expect(output.call(:not_a_string).left?).to eq(true)
      end
    end

    context "without a block" do
      it "raises an argument error" do
        expect { subject.to(Integer) }
          .to raise_error(ArgumentError, 'No transform registered to transform String to Integer. Perhaps you should use the block form?')
      end
    end

    context "without a block for a subclass with a non empty transform registry" do
      subject { Alchemrest::Transforms::FromString.new }

      it "returns a valid `ToType` transform" do
        expect(subject.to(Date)).to be_a(Alchemrest::Transforms::ToType)
      end
    end
  end
end
