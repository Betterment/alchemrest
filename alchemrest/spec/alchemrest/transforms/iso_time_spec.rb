# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::IsoTime do
  subject { described_class.new(to_timezone:, require_offset:) }
  let(:to_timezone) { nil }
  let(:require_offset) { true }

  describe "#call" do
    context "when we specify the timezone" do
      let(:to_timezone) { "Eastern Time (US & Canada)" }

      context "and the input has a defined offset" do
        let(:input) { "2018-01-01T12:00:00Z" }
        it "returns a time converted to the specified zone" do
          result = subject.call(input).from_right
          expect(result)
            .to eq(ActiveSupport::TimeZone[to_timezone].local(2018, 1, 1, 7, 0, 0))
          expect(result).to be_a(ActiveSupport::TimeWithZone)
          expect(result.zone).to eq("EST")
        end
      end

      context "and the input does not have a defined offset and require_offset: false" do
        let(:input) { "2018-01-01T12:00:00" }
        let(:require_offset) { false }

        it "returns a time assumed to be the specified zone" do
          result = subject.call(input).from_right
          expect(result)
            .to eq(ActiveSupport::TimeZone[to_timezone].local(2018, 1, 1, 12, 0, 0))
          expect(result).to be_a(ActiveSupport::TimeWithZone)
          expect(result.zone).to eq("EST")
        end
      end

      context "and the input does not have a defined offset and require_offset: true" do
        let(:input) { "2018-01-01T12:00:00" }
        let(:require_offset) { true }
        let(:error) do
          Morpher::Transform::Error.new(
            cause: nil,
            input:,
            transform: subject,
            message: "Expected #{input} to have a valid ISO timezone offset",
          )
        end

        it "errors" do
          expect(subject.call(input).from_left)
            .to eq(error)
        end
      end
    end

    context "when the input is a valid iso time string" do
      it "returns a time object" do
        result = subject.call("2018-01-01T12:00:00Z").from_right
        expect(result).to eq(Time.utc(2018, 1, 1, 12, 0, 0))
        expect(result).to be_a(Time)
      end
    end

    context "when the input is a non UTC iso time string" do
      it "parses it into a Time object with the specified offset" do
        result = subject.call("2018-01-01T12:00:00-0400").from_right
        expect(result)
          .to eq(Time.new(2018, 1, 1, 12, 0, 0, "-0400"))

        expect(result).to be_a(Time)
        expect(result.zone).to eq(nil)
      end
    end

    context "for iso time of higher precision" do
      it "returns a time object" do
        expect(subject.call("2018-01-01T12:00:00.123456Z").from_right).to eq(Time.utc(2018, 1, 1, 12, 0, 0, 123_456))
      end
    end

    context "for a variety of iso formats" do
      let(:strings) do
        [
          '2025-01-01T00:00Z',
          '2025-01-01T00:00+0400',
          '2025-01-01T00:00-0400',
          '2025-01-01',
        ]
      end

      let(:to_timezone) { "UTC" }
      let(:require_offset) { true }

      it "can parse successfully" do
        strings.each do |string|
          expect(subject.call(string).from_right).to be_a(ActiveSupport::TimeWithZone)
        end
      end
    end

    context "for an invalid iso time string" do
      let(:input) { "2018-01-01T12:00:0Z" }
      let(:error) do
        Morpher::Transform::Error.new(
          cause: nil,
          input:,
          transform: subject,
          message: "Expected #{input} to be iso datetime string",
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
          message: "Expected #{input} to be iso datetime string",
        )
      end
      it "returns a failure" do
        expect(subject.call(input).from_left).to eql(error)
      end
    end
  end
end
