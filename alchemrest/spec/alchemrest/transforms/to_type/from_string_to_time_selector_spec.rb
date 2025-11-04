# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::ToType::FromStringToTimeSelector do
  subject { described_class.new(Alchemrest::Transforms::FromString.new) }

  describe "self.new" do
    it "can be built" do
      expect(subject).to be_a(described_class)
    end
  end

  describe "#using" do
    context ":utc" do
      let(:using) { :utc }

      it "returns a to type transform set to use utc" do
        transform = subject.using(using)
        expect(transform).to be_a(Alchemrest::Transforms::ToType)
        expect(transform.to).to eq(ActiveSupport::TimeWithZone)
        expect(transform.use.sole.require_offset).to eq(true)
        expect(transform.use.sole.to_timezone).to eq("UTC")
      end
    end

    context ":local" do
      let(:using) { :local }

      it "returns a to type transform set to use local time" do
        Time.use_zone("Mountain Time (US & Canada)") do
          transform = subject.using(using)
          expect(transform).to be_a(Alchemrest::Transforms::ToType)
          expect(transform.to).to eq(ActiveSupport::TimeWithZone)
          expect(transform.use.sole.require_offset).to eq(true)
          expect(transform.use.sole.to_timezone).to eq(Time.zone.name)
        end
      end
    end

    context "zone" do
      let(:using) { "Mountain Time (US & Canada)" }

      it "returns a to type transform set to using the specified zone" do
        transform = subject.using(using)
        expect(transform).to be_a(Alchemrest::Transforms::ToType)
        expect(transform.to).to eq(ActiveSupport::TimeWithZone)
        expect(transform.use.sole.require_offset).to eq(true)
        expect(transform.use.sole.to_timezone).to eq(using)
      end
    end

    context "offset" do
      let(:using) { :offset }

      it "returns a to type transform set to using the specified zone" do
        transform = subject.using(using)
        expect(transform).to be_a(Alchemrest::Transforms::ToType)
        expect(transform.to).to eq(Time)
        expect(transform.use.sole.require_offset).to eq(true)
        expect(transform.use.sole.to_timezone).to eq(nil)
      end
    end

    context "require_offset: false" do
      let(:using) { :utc }

      it "returns a to type transform set to using the specified zone" do
        transform = subject.using(using, require_offset: false)
        expect(transform).to be_a(Alchemrest::Transforms::ToType)
        expect(transform.to).to eq(ActiveSupport::TimeWithZone)
        expect(transform.use.sole.require_offset).to eq(false)
        expect(transform.use.sole.to_timezone).to eq("UTC")
      end

      context "using: :offset" do
        it "raises" do
          expect { subject.using(:offset, require_offset: false) }
            .to raise_error(ArgumentError, "require_offset cannot be false when using :offset")
        end
      end
    end
  end
end
