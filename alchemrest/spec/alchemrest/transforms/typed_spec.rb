# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::Typed do
  let(:constraints) { [] }
  let(:output_type) { Alchemrest::Transforms::OutputType.new(sorbet_type: type, constraints:) }
  subject { described_class.new(transform:, output_type:) }
  let(:transform) do
    Morpher::Transform::STRING.seq(Morpher::Transform::Block.capture("to symbol") { |input| Morpher::Either::Right.new(input.to_sym) })
  end
  let(:type) { Symbol }

  describe "#call" do
    it "calls the underlying transform" do
      expect(subject.call("foo").from_right).to eq(:foo)
    end
  end

  describe "#array" do
    it "calls the underlying transform" do
      array = subject.array
      expect(array.transform).to eq Morpher::Transform::Array.new(subject)
      expect(array.output_type).to eq Alchemrest::Transforms::OutputType.simple(T::Array[subject.output_type.sorbet_type])
    end
  end

  describe "#output_type" do
    it "provides the output type" do
      expect(subject.output_type).to eq(Alchemrest::Transforms::OutputType.simple(type))
    end
  end

  describe "array" do
    it "returns a typed collection transform" do
      transform = subject.array

      expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.simple(T::Array[Symbol])
      expect(transform.call(["foo"]).from_right).to eq([:foo])
    end

    context "with constraints" do
      let(:constraints) { [Alchemrest::Transforms::Constraint::MaxLength.new(10)] }

      it "preserves them" do
        transform = subject.array

        expect(transform.output_type.constraints).to eq constraints
      end
    end
  end

  describe "maybe" do
    it "returns a typed nilable transform" do
      transform = subject.maybe

      expect(transform.output_type).to eq Alchemrest::Transforms::OutputType.simple(T.nilable(Symbol))
      expect(transform.call("foo").from_right).to eq(:foo)
      expect(transform.call(nil).from_right).to eq(nil)
    end

    context "with constraints" do
      let(:constraints) { [Alchemrest::Transforms::Constraint::MaxLength.new(10)] }

      it "preserves them" do
        transform = subject.maybe

        expect(transform.output_type.constraints).to eq constraints
      end
    end
  end
end
