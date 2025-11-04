# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::DateTransform do
  subject { described_class.new }

  describe "#call" do
    context "when the input is a valid iso date string" do
      it "returns a time object" do
        expect(subject.call("2018-01-01").from_right).to eql(Date.new(2018, 1, 1))
      end
    end

    context "for an invalid date string" do
      let(:input) { "2018-01-1" }
      let(:error) do
        Morpher::Transform::Error.new(
          cause: nil,
          input:,
          transform: subject,
          message: "Expected #{input} to be an iso date string",
        )
      end

      it "returns a failure" do
        expect(subject.call(input).from_left).to eql(error)
      end
    end

    context "for a non-string input" do
      let(:input) { 123 }
      let(:error) do
        Morpher::Transform::Error.new(
          cause: nil,
          input:,
          transform: subject,
          message: "Expected #{input} to be an iso date string",
        )
      end
      it "returns a failure" do
        expect(subject.call(input).from_left).to eql(error)
      end
    end
  end
end
