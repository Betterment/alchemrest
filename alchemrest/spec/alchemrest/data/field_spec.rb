# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Data::Field do
  subject { described_class.new(transform:, name:, required:) }
  let(:transform) { Alchemrest::Transforms::Number.new }
  let(:name) { :age }
  let(:required) { false }

  describe "new" do
    it "builds" do
      expect { subject }.not_to raise_error
      expect(subject).to be_a(described_class)
    end

    context "when transform is an Alchemrest::Data" do
      let(:transform_class) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                id: s.string,
              },
            }
          end
        end
      end
      let(:transform) { transform_class.from_hash({ id: 'asdf' }) }

      it "builds" do
        expect { subject }.not_to raise_error
        expect(subject).to be_a(described_class)
      end
    end

    context "when transform is not a valid type" do
      let(:transform) { Class.new }

      it "does raise" do
        expect { subject }
          .to raise_error(ArgumentError, "transform must be an instance of Morpher::Transform or Alchemrest::Data, not Class")
      end
    end

    context "when name nil" do
      let(:name) { nil }

      it "does raise" do
        expect { subject }.to raise_error(ArgumentError, "must provide name")
      end
    end

    context "when name is an empty string" do
      let(:name) { '' }

      it "does raise" do
        expect { subject }.to raise_error(ArgumentError, "must provide non-empty name")
      end
    end

    context "when name is an blank string" do
      let(:name) { ' ' }

      it "does raise" do
        expect { subject }.to raise_error(ArgumentError, "must provide non-empty name")
      end
    end

    context "when name is an non-empty string" do
      let(:name) { 'age' }

      it "builds" do
        expect { subject }.not_to raise_error
        expect(subject).to be_a(described_class)
      end
    end
  end

  describe "#transform" do
    it "returns the transform" do
      expect(subject.transform).to eq transform
    end
  end

  describe "#name" do
    it "returns the name as a string" do
      expect(subject.name).to eq 'age'
    end
  end

  describe "#constraints" do
    context "when the transform is a type with constraints" do
      let(:transform) { Alchemrest::Transforms::FromString.new.where.must_be_uuid }

      it "returns the constraints from the underlying transform" do
        expect(subject.constraints).to eq [Alchemrest::Transforms::Constraint::IsUuid.new]
      end
    end

    context "when the transform is a type which defines a `constraint` method, but has no constraints" do
      let(:transform) { Alchemrest::Transforms::FromString.new }

      it "returns the constraints from the underlying transform" do
        expect(subject.constraints).to eq []
      end
    end

    context "when the transform doesn't have a constraints method" do
      let(:transform) { Morpher::Transform::INTEGER }

      it "returns an empty array" do
        expect(subject.constraints).to eq []
      end
    end
  end

  describe "#output_type" do
    context "when the transform doesn't provide an output_type" do
      let(:transform) { Morpher::Transform::INTEGER }

      it "returns nil" do
        expect(subject.output_type).to eq(nil)
      end
    end

    context "when the field is required and provides and the transform provides an output type" do
      let(:transform) { Alchemrest::Transforms.number }
      let(:required) { true }

      it "returns the output type" do
        expect(subject.output_type).to eq(Alchemrest::Transforms::OutputType.simple(T.any(Float, Integer)))
      end
    end

    context "when the field is not required and provides and the transform provides an output type" do
      let(:transform) { Alchemrest::Transforms.number }
      let(:required) { false }

      it "returns the nilable output type" do
        expect(subject.output_type).to eq(Alchemrest::Transforms::OutputType.simple(T.nilable(T.any(Float, Integer))))
      end
    end
  end

  describe "#required" do
    context "when required is not specified" do
      subject { described_class.new(transform:, name:) }

      it "returns false as default value" do
        expect(subject.required).to eq false
      end
    end

    context "when required is false" do
      let(:required) { false }

      it "returns false" do
        expect(subject.required).to eq false
      end
    end

    context "when required is true" do
      let(:required) { true }

      it "returns true" do
        expect(subject.required).to eq true
      end
    end

    context "when required is true but transform is a Morpher::Transform::Maybe" do
      let(:transform) { Morpher::Transform::Maybe.new(Alchemrest::Transforms::Number.new) }
      let(:required) { true }

      it "returns false" do
        expect(subject.required).to eq false
      end
    end
  end
end
