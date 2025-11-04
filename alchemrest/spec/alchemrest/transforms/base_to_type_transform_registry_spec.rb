# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::BaseToTypeTransformRegistry do
  let(:implementation) do
    Class.new(described_class) do
      attr_reader :test_transforms

      def initialize(from, transforms)
        @test_transforms = transforms
        super(from)
      end

      def build_transforms
        @test_transforms
      end
    end
  end

  let(:from) { Alchemrest::Transforms::FromType.new(type: String) }
  subject { implementation.new(from, registered_transforms) }

  let(:parse_transform) { Morpher::Transform::Success.new(->(input) { input.to_i }) }
  let(:measure_transform) { Morpher::Transform::Success.new(->(input) { input.length }) }

  describe "#resolve" do
    context "when the type resolves to an array of transforms" do
      let(:registered_transforms) do
        {
          Integer => [parse_transform],
        }
      end

      it "returns a ToType transform using that array" do
        expected = Alchemrest::Transforms::ToType.new(from:, to: Integer, use: [parse_transform])
        result = subject.resolve(Integer)
        expect(result).to eq(expected)
      end
    end

    context "when the type resolves to a hash of options" do
      let(:registered_transforms) do
        {
          Integer => {
            parse: [parse_transform],
            measure: [measure_transform],
          },
        }
      end

      it "returns a ToType::TransformsSelector with those options" do
        expected = Alchemrest::Transforms::ToType::TransformsSelector.new(
          from,
          Integer,
          { parse: [parse_transform], measure: [measure_transform] },
        )
        expect(subject.resolve(Integer)).to eq(expected)
      end
    end

    context "when the type resolves to custom selector" do
      let(:implementation) do
        Class.new(described_class) do
          def build_transforms
            {
              Time => Alchemrest::Transforms::ToType::FromStringToTimeSelector.new(from),
            }
          end
        end
      end

      subject { implementation.new(from) }

      it "returns that selector" do
        expect(subject.resolve(Time)).to be_an_instance_of(Alchemrest::Transforms::ToType::FromStringToTimeSelector)
      end
    end

    context "when the type resolves some uknown thing" do
      let(:registered_transforms) do
        {
          Integer => "foo",
        }
      end

      it "raises" do
        expect { subject.resolve(Integer) }.to raise_error("Not a valid implementation of `def build_transforms`")
      end
    end

    context "when the type does not resolve to anything" do
      let(:registered_transforms) do
        {
          Integer => [parse_transform],
        }
      end

      it "raises" do
        expect {
          subject.resolve(String)
        }.to raise_error Alchemrest::NoRegisteredTransformError, "No registered transform for String -> String"
      end
    end
  end
end
