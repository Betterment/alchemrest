# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::Constrainable do
  let(:constrainable_primitive) do
    klass = Class.new(Morpher::Transform) do
      include Alchemrest::Transforms::Constrainable.new(additional_attributes: %i(type description))

      def call(input)
        validate_constraints.call(input)
      end
    end
    klass.new(type: String, description: "a string", constraints:)
  end

  let(:simple_constrainable) do
    simple_constrainable = Class.new(Morpher::Transform) do
      include Alchemrest::Transforms::Constrainable.new

      def call(input)
        validate_constraints.call(input)
      end
    end

    simple_constrainable.new(constraints:)
  end
  let(:constraints) { [] }

  describe "behaves like constrainable" do
    subject { simple_constrainable }

    it_behaves_like "constrainable", predicate: ->(input) { input.start_with?("a") }, passing_input: "apple", failing_input: "orange"
  end

  describe ".new" do
    context "with additional attributes" do
      subject { constrainable_primitive }

      it "has the other attributes" do
        expect(subject.type).to eq(String)
        expect(subject.description).to eq("a string")
      end
    end

    context "with no additional attributes" do
      let(:constraints) do
        [Alchemrest::Transforms::Constraint::Block.new("is foo") { |input| input == "foo" }]
      end

      subject { simple_constrainable }

      it "builds a callable transform" do
        expect(subject.call("foo").from_right).to eq("foo")
        expect(subject.call("bar").from_left.compact_message).to match(/does not meet the constraint "is foo"/)
      end
    end

    context "with no constraints" do
      let(:constraints) { [] }
      subject { simple_constrainable }

      it "builds a callable transform" do
        expect(subject.call("foo").from_right).to eq("foo")
      end
    end
  end
end
