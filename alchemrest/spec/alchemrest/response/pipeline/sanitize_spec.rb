# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Response::Pipeline::Sanitize do
  subject { described_class.new(safe: safe_paths) }

  let(:safe_paths) { nil }

  describe "#call" do
    context "with a hash with no sensitive keys" do
      let(:input) { { name: "Betterbot", age: 20 } }

      it "returns succesfully with an unchanged output" do
        expect(subject.call(input).from_right).to eq(input)
      end
    end

    context "with an array of hashes with no sensitive keys" do
      let(:input) { [{ name: "Betterbot", age: 20 }, { name: "Betterbot", age: 20 }] }

      it "returns succesfully with an unchanged output" do
        expect(subject.call(input).from_right).to eq(input)
      end
    end

    context "with a hash with sensitive keys" do
      let(:input) { { name: "Betterbot", age: 20, ssn: "1235402" } }

      it "returns succesfully a filtered output" do
        expect(subject.call(input).from_right)
          .to eq({ name: "Betterbot", age: 20, ssn: "[FILTERED]" })
      end
    end

    context "with a hash with an array of sensitive keys" do
      let(:input) do
        [
          { name: "Betterbot", age: 20, ssn: "1235402" },
          { name: "BetterBear", age: 20, ssn: "1235402" },
        ]
      end

      it "returns succesfully a filtered output" do
        expect(subject.call(input).from_right)
          .to eq([
            { name: "Betterbot", age: 20, ssn: "[FILTERED]" },
            { name: "BetterBear", age: 20, ssn: "[FILTERED]" },
          ])
      end
    end

    context "with a hash with sensitive keys as a string" do
      let(:input) { { name: "Betterbot", age: 20, "ssn" => "1235402" } }

      it "returns succesfully a filtered output where the original key was a string, but the output is all symbols" do
        expect(subject.call(input).from_right)
          .to eq({ name: "Betterbot", age: 20, ssn: "[FILTERED]" })
      end
    end

    context "with a safe hash path array" do
      let(:input) { { name: "Betterbot", age: 20, ssn: "1235402" } }

      let(:safe_paths) { Alchemrest::HashPath.build_collection(%i(ssn)) }

      it "returns succesfully a filtered output with restored safe string keys" do
        expect(subject.call(input).from_right)
          .to eq({ name: "Betterbot", age: 20, ssn: "1235402" })
      end
    end

    context "with something that's not a hash" do
      let(:input) { 1 }

      it "returns an error" do
        expect(subject.call(input).from_left)
          .to be_a(Morpher::Transform::Error)
      end
    end

    context "with an array of things that aren't hashes" do
      let(:input) { [1, 2] }

      it "returns an error" do
        expect(subject.call(input).from_left)
          .to be_a(Morpher::Transform::Error)
      end
    end
  end
end
