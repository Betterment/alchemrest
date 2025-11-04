# frozen_string_literal: true

require 'spec_helper'

shared_examples_for "constrainable" do |predicate:, passing_input:, failing_input:|
  describe "#where" do
    context "when a block and description is provided" do
      it "returns a new transform with the constraint added" do
        output = subject.where("passes predicate", &predicate)
        expect(output.constraints.count).to eq(1)
        expect(output.constraints.first.description).to eq("passes predicate")
        expect(output.call(passing_input).right?).to eq(true)
        expect(output.call(failing_input).left?).to eq(true)
      end
    end

    context "when an implementation of Alchemrest::Transforms::Constraint is provided" do
      let(:constraint) do
        Alchemrest::Transforms::Constraint::Block.new("passes predicate", &predicate)
      end

      it "returns a new transform with the constraint added" do
        output = subject.where(constraint)
        expect(output.constraints.count).to eq(1)
        expect(output.constraints.first.description).to eq("passes predicate")
        expect(output.call(passing_input).right?).to eq(true)
        expect(output.call(failing_input).left?).to eq(true)
      end
    end

    context "when it has existing failing constraints" do
      let(:constraint) do
        Alchemrest::Transforms::Constraint::Block.new("passes predicate", &predicate)
      end

      let(:always_false) do
        Alchemrest::Transforms::Constraint::Block.new("always false") { |_input| false }
      end

      it "returns a new transform with the constraint added" do
        output = subject.with(constraints: [always_false]).where(constraint)
        expect(output.constraints.count).to eq(2)
        expect(output.constraints.first.description).to eq("always false")
        expect(output.constraints.last.description).to eq("passes predicate")
        expect(output.call(passing_input).left?).to eq(true)
        expect(output.call(failing_input).left?).to eq(true)
      end
    end

    context "when it has existing passing constraints" do
      let(:constraint) do
        Alchemrest::Transforms::Constraint::Block.new("passes predicate", &predicate)
      end

      let(:always_true) do
        Alchemrest::Transforms::Constraint::Block.new("always true") { |_input| true }
      end

      it "returns a new transform with the constraint added" do
        output = subject.with(constraints: [always_true]).where(constraint)
        expect(output.constraints.count).to eq(2)
        expect(output.constraints.first.description).to eq("always true")
        expect(output.constraints.last.description).to eq("passes predicate")
        expect(output.call(passing_input).right?).to eq(true)
        expect(output.call(failing_input).left?).to eq(true)
      end
    end

    context "when there is no block provided and the only argument is not a constraint instance" do
      it "raises an ArgumentError" do
        expect { subject.where("foo") }.to raise_error ArgumentError, "Must provide an instance of Alchemrest::Transform::Constraint"
      end
    end
  end
end
