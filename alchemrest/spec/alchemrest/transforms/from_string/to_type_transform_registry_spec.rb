# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Transforms::FromString::ToTypeTransformRegistry do
  let(:from) { Alchemrest::Transforms::FromString.new }
  subject { described_class.new(from) }

  describe "#resolve" do
    context "with Time" do
      context "using utc" do
        it "returns a callable time transform that parses the value to a utc time" do
          transform = subject.resolve(Time).using(:utc)
          result = transform.call("2016-01-01T00:00:00Z").from_right
          expect(result).to eq(Time.utc(2016, 1, 1, 0, 0, 0))
          expect(result).to be_a(ActiveSupport::TimeWithZone)
          expect(result.zone).to eq("UTC")
        end

        context "with a string with no timezone" do
          it "returns an error" do
            transform = subject.resolve(Time).using(:utc)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone and require_offset: true" do
          it "returns an error" do
            transform = subject.resolve(Time).using(:utc, require_offset: true)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone information and require_offset: false" do
          it "assumes utc timezone" do
            transform = subject.resolve(Time).using(:utc, require_offset: false)
            result = transform.call("2016-01-01T00:00:00").from_right
            expect(result).to eq(Time.utc(2016, 1, 1, 0, 0, 0))
            expect(result).to be_a(ActiveSupport::TimeWithZone)
            expect(result.zone).to eq("UTC")
          end
        end
      end

      context "using offset" do
        it "returns a callable time transform that sets the offset but has no specified zone" do
          transform = subject.resolve(Time).using(:offset)
          result = transform.call("2016-01-01T00:00:00-0400").from_right
          expect(result).to eq(Time.new(2016, 1, 1, 0, 0, 0, "-0400"))
          expect(result).to be_a(Time)
          expect(result.zone).to eq(nil)
        end

        context "with a string with no timezone" do
          it "returns an error" do
            transform = subject.resolve(Time).using(:offset)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone and require_offset: true" do
          it "returns an error" do
            transform = subject.resolve(Time).using(:offset, require_offset: true)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone information and require_offset: false" do
          it "raises" do
            expect { subject.resolve(Time).using(:offset, require_offset: false) }
              .to raise_error(ArgumentError, "require_offset cannot be false when using :offset")
          end
        end
      end

      context "using local" do
        around do |example|
          Time.use_zone("Eastern Time (US & Canada)") { example.run }
        end

        it "returns a callable time transform that sets the zone to `Time.zone`" do
          transform = subject.resolve(Time).using(:local)
          result = transform.call("2016-01-01T00:00:00Z").from_right
          expect(result).to eq(Time.utc(2016, 1, 1, 0, 0, 0))
          expect(result).to be_a(ActiveSupport::TimeWithZone)
          expect(result.zone).to eq("EST")
        end

        context "with a string with no timezone" do
          it "returns an error" do
            transform = subject.resolve(Time).using(:local)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone and require_offset: true" do
          it "returns an error" do
            transform = subject.resolve(Time).using(:local, require_offset: true)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone information and require_offset: false" do
          it "assumes the local timezone" do
            transform = subject.resolve(Time).using(:local, require_offset: false)
            result = transform.call("2016-01-01T00:00:00").from_right
            expect(result).to eq(Time.zone.local(2016, 1, 1, 0, 0, 0))
            expect(result).to be_a(ActiveSupport::TimeWithZone)
            expect(result.zone).to eq("EST")
          end
        end
      end

      context "using a specific timezone" do
        let(:zone_name) { 'Mountain Time (US & Canada)' }
        it "returns a callable time transform that sets the zone to the specified zone" do
          transform = subject.resolve(Time).using(zone_name)
          result = transform.call("2016-01-01T00:00:00Z").from_right
          expect(result).to eq(Time.utc(2016, 1, 1, 0, 0, 0))
          expect(result).to be_a(ActiveSupport::TimeWithZone)
          expect(result.zone).to eq("MST")
        end

        context "with a string with no timezone" do
          it "returns an error" do
            transform = subject.resolve(Time).using(zone_name)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone and requires_offset: true" do
          it "returns an error" do
            transform = subject.resolve(Time).using(zone_name, require_offset: true)
            error = transform.call("2016-01-01T00:00:00").from_left
            expect(error).to be_a(Morpher::Transform::Error)
          end
        end

        context "with a string with no timezone information and require_offset false" do
          it "assumes the specified timezone" do
            transform = subject.resolve(Time).using(zone_name, require_offset: false)
            result = transform.call("2016-01-01T00:00:00").from_right
            expect(result).to eq(ActiveSupport::TimeZone[zone_name].local(2016, 1, 1, 0, 0, 0))
            expect(result).to be_a(ActiveSupport::TimeWithZone)
            expect(result.zone).to eq("MST")
          end
        end
      end
    end

    context "with Date" do
      it "returns a callable date transform" do
        transform = subject.resolve(Date)
        expect(transform.call("2016-01-01").from_right).to eq(Date.new(2016, 1, 1))
      end
    end

    context "with BigDecimal" do
      it "returns a callable decimal transform" do
        transform = subject.resolve(BigDecimal)
        expect(transform.call("123.456").from_right).to eq(BigDecimal("123.456"))
      end
    end

    context "with an unregistered type" do
      it "raises an error" do
        expect {
          subject.resolve(String)
        }.to raise_error(Alchemrest::NoRegisteredTransformError, "No registered transform for String -> String")
      end
    end
  end
end
