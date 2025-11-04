# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::OutputType, squad: :employee_wellness do
  let(:constraints) { [] }
  subject { described_class.new(sorbet_type: type, constraints:) }

  describe "self.simple" do
    let(:type) { Integer }
    it "lets you build a output type with only a sorbet type" do
      expect(described_class.simple(type)).to eq(described_class.new(sorbet_type: type, constraints: []))
    end
  end

  describe "#graph" do
    context "for a simple type" do
      let(:type) { String }

      it "returns nil" do
        expect(subject.graph).to eq(nil)
      end
    end

    context "for a sorbet union type" do
      let(:type) { T.any(Integer, Float) }

      it "returns nil" do
        expect(subject.graph).to eq(nil)
      end
    end

    context "for a type that implements Alchemrest::Data" do
      let(:type) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
            }
          end
        end
      end

      it "returns the type's graph" do
        expect(subject.graph).to eq(type.graph)
      end
    end

    context "for a nilable type that implements Alchemrest::Data" do
      let(:base_type) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
            }
          end
        end
      end

      let(:type) { T.nilable(base_type) }

      it "returns the types graph" do
        expect(subject.graph).to eq(base_type.graph)
      end
    end

    context "for a boolean type" do
      let(:type) { T::Boolean }

      it "returns nil" do
        expect(subject.graph).to be_nil
      end
    end

    context "for a array type of an alchemerst class" do
      let(:type) { T::Array[base_type] }
      let(:base_type) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
            }
          end
        end
      end

      it "returns the graph of the alchemerst class" do
        expect(subject.graph).to eq(base_type.graph)
      end
    end

    context "for a nilable array type of an alchemerst class" do
      let(:type) { T.nilable(T::Array[base_type]) }
      let(:base_type) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
            }
          end
        end
      end

      it "returns graph of the alchemrest class" do
        expect(subject.graph).to eq(base_type.graph)
      end
    end
  end

  describe "#with" do
    let(:type) { Integer }
    let(:constraints) { [Alchemrest::Transforms::Constraint::GreaterThan.new(10)] }

    it "lets you override constraints" do
      new_constraints = [Alchemrest::Transforms::Constraint::GreaterThan.new(5)]
      new_output = subject.with(constraints: new_constraints)
      expect(new_output).to eq(described_class.new(sorbet_type: type, constraints: new_constraints))
    end

    it "lets you override type" do
      new_output = subject.with(sorbet_type: T.nilable(type))
      expect(new_output).to eq(described_class.new(sorbet_type: T.nilable(type), constraints:))
    end
  end

  describe "#==" do
    let(:other) do
      described_class.new(sorbet_type: other_type, constraints: other_constraints)
    end

    context "when all values match" do
      let(:type) { Integer }
      let(:other_type) { type }
      let(:constraints) { [Alchemrest::Transforms::Constraint::GreaterThan.new(10)] }
      let(:other_constraints) { [Alchemrest::Transforms::Constraint::GreaterThan.new(10)] }

      it "returns true" do
        expect(subject == other).to eq(true)
      end
    end

    context "when constraints differ" do
      let(:type) { Integer }
      let(:other_type) { type }
      let(:constraints) { [Alchemrest::Transforms::Constraint::GreaterThan.new(10)] }
      let(:other_constraints) { [Alchemrest::Transforms::Constraint::GreaterThan.new(5)] }

      it "returns false" do
        expect(subject == other).to eq(false)
      end
    end

    context "when types differ" do
      let(:type) { Integer }
      let(:other_type) { T.nilable(type) }
      let(:constraints) { [Alchemrest::Transforms::Constraint::GreaterThan.new(10)] }
      let(:other_constraints) { [Alchemrest::Transforms::Constraint::GreaterThan.new(10)] }

      it "returns false" do
        expect(subject == other).to eq(false)
      end
    end
  end
end
