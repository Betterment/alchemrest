# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Response::Pipeline::Omit do
  subject { described_class.new(omit_paths) }

  let(:omit_paths) { nil }

  describe "#call" do
    context "with an input that is not a hash" do
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

    context "with a hash that has no omit paths" do
      let(:input) { { name: "Betterbot", age: 20 } }

      it "returns succesfully with an unchanged output" do
        expect(subject.call(input).from_right).to eq(input)
      end
    end

    context "with a hash that has an omit path that is included" do
      let(:input) { { name: "Betterbot", age: 20, ssn: "1235402" } }

      let(:omit_paths) { Alchemrest::HashPath.build_collection(%i(ssn)) }

      it "returns succesfully with the leaf node omited" do
        expect(subject.call(input).from_right)
          .to eq({ name: "Betterbot", age: 20 })
      end
    end

    context "with a hash that has multiple omit paths that are included" do
      let(:input) { { name: "Betterbot", age: 20, ssn: "1235402" } }

      let(:omit_paths) { Alchemrest::HashPath.build_collection(%i(age ssn)) }

      it "returns succesfully with the leaf node omited" do
        expect(subject.call(input).from_right)
          .to eq({ name: "Betterbot" })
      end
    end

    context "with a hash with and array and an omit path that is included" do
      let(:input) do
        [
          { name: "Betterbot", age: 20, ssn: "1235402" },
          { name: "BetterBear", age: 20, ssn: "1235402" },
        ]
      end

      let(:omit_paths) { Alchemrest::HashPath.build_collection(%i(ssn)) }

      it "returns succesfully an omitted output" do
        expect(subject.call(input).from_right)
          .to eq([
            { name: "Betterbot", age: 20 },
            { name: "BetterBear", age: 20 },
          ])
      end
    end

    context "with a hash that has an omit path that is not included" do
      let(:input) { { name: "Betterbot", age: 20, ssn: "1235402" } }

      let(:omit_paths) { Alchemrest::HashPath.build_collection(%i(address)) }
      it "returns succesfully without omiting nodes" do
        expect(subject.call(input).from_right)
          .to eq({ name: "Betterbot", age: 20, ssn: "1235402" })
      end
    end
  end
end
