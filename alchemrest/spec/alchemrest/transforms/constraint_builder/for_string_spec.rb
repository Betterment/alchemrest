# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::ConstraintBuilder::ForString do
  let(:constrainable) { Alchemrest::Transforms::FromString.new }
  subject { described_class.new(constrainable) }

  describe "#max_length" do
    it "adds a MaxLength constraint to the constrainable" do
      expect(subject.max_length(3)).to be_a(Alchemrest::Transforms::FromString)
      expect(subject.max_length(3).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::MaxLength.new(3))
    end
  end

  describe "#min_length" do
    it "adds a MinLength constraint to the constrainable" do
      expect(subject.min_length(3)).to be_a(Alchemrest::Transforms::FromString)
      expect(subject.min_length(3).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::MinLength.new(3))
    end
  end

  describe "#matches" do
    it "adds a MatchesRegex constraint to the constrainable" do
      expect(subject.matches(/foo/)).to be_a(Alchemrest::Transforms::FromString)
      expect(subject.matches(/foo/).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::MatchesRegex.new(/foo/))
    end
  end

  describe "#in" do
    it "adds a InList constraint to the constrainable" do
      expect(subject.in(%w(foo bar baz))).to be_a(Alchemrest::Transforms::FromString)
      expect(subject.in(%w(foo bar baz)).constraints).to contain_exactly(Alchemrest::Transforms::Constraint::InList.new(%w(foo bar baz)))
    end
  end

  describe "#must_be_uuid" do
    it "adds a MatchesRegex constraint to the constrainable" do
      expect(subject.must_be_uuid).to be_a(Alchemrest::Transforms::FromString)
      expect(subject.must_be_uuid.constraints).to contain_exactly(Alchemrest::Transforms::Constraint::IsUuid.new)
    end
  end
end
