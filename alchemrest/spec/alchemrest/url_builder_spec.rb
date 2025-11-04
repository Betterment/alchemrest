# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::UrlBuilder do
  subject { described_class.new(template:, query:, values:, query_param_encoder:) }

  let(:template) { "/api/users/:id" }
  let(:values) { { id: SecureRandom.uuid } }
  let(:query) { nil }
  let(:query_param_encoder) { nil }

  describe "#initialize" do
    it "defaults to the FormUrlEncoded encoder" do
      expect(subject.query_param_encoder).to be_an_instance_of(Alchemrest::UrlBuilder::Encoders::FormUrlEncoded)
    end

    let(:values) { { id: SecureRandom.uuid } }
    let(:query) { { includeDetails: true } }

    it "does not raise" do
      expect(subject).to be_an_instance_of(described_class)
    end

    context "when missing `values`" do
      subject { described_class.new(template:, query:, query_param_encoder:) }

      it "does not raise" do
        expect(subject).to be_an_instance_of(described_class)
      end
    end

    context "when missing `query`" do
      subject { described_class.new(template:, values:, query_param_encoder:) }

      it "does not raise" do
        expect(subject).to be_an_instance_of(described_class)
      end
    end
  end

  describe "#url" do
    context "with no values" do
      let(:values) { nil }
      it "returns the template" do
        expect(subject.url).to eq template
      end
    end

    context "with an empty query" do
      let(:values) { { id: SecureRandom.uuid } }
      let(:query) { {} }

      it "leaves off the '?'" do
        expect(subject.url).to eq "/api/users/#{values[:id]}"
      end
    end

    context "with a query with null values" do
      let(:values) { { id: SecureRandom.uuid } }
      let(:query) { { includeDetails: true, offset: nil } }

      it "strips out the nulls" do
        expect(subject.url).to eq "/api/users/#{values[:id]}?includeDetails=true"
      end
    end

    context "with a query with only null values" do
      let(:values) { { id: SecureRandom.uuid } }
      let(:query) { { includeDetails: nil, offset: nil } }

      it "does not include the '?'" do
        expect(subject.url).to eq "/api/users/#{values[:id]}"
      end
    end

    context "when values that match the template placeholders are provided" do
      let(:values) { { id: SecureRandom.uuid } }

      it "replaces the placeholders" do
        expect(subject.url).to eq "/api/users/#{values[:id]}"
      end
    end

    context "when values that do not match the template placeholders are provided" do
      let(:values) { { id: SecureRandom.uuid, name: 'test' } }

      it "raises" do
        expect { subject.url }.to raise_error(Mustermann::ExpandError)
      end
    end

    context "when values that are missing template placeholders are provided" do
      let(:values) { {} }
      it "raises" do
        expect { subject.url }.to raise_error(Mustermann::ExpandError)
      end
    end

    context "when query values are provided" do
      let(:values) { { id: SecureRandom.uuid } }
      let(:query) { { names: %w(foo bar) } }

      context "and no encoder is provided" do
        it "encodes the query string using the application/x-www-form-urlencoded encoding" do
          expect(subject.url).to eq "/api/users/#{values[:id]}?names=foo&names=bar"
        end
      end

      context "when the form encoded is provided" do
        let(:query_param_encoder) { described_class::Encoders.find(:form) }
        it "encodes the query string using the application/x-www-form-urlencoded encoding" do
          expect(subject.url).to eq "/api/users/#{values[:id]}?names=foo&names=bar"
        end
      end

      context "when the rack encoder is provided" do
        let(:query_param_encoder) { described_class::Encoders.find(:rack) }

        it "encodes the query string using Racks nested query format" do
          expect(CGI.unescape(subject.url)).to eq "/api/users/#{values[:id]}?names[]=foo&names[]=bar"
        end
      end

      context "and a custom encoder class is provided" do
        let(:query_param_encoder) do
          Class.new {
            def call(query)
              query.values.join(",")
            end
          }.new
        end

        it "encodes the query string using that class's call method" do
          expect(subject.url).to eq "/api/users/#{values[:id]}?foo,bar"
        end
      end

      context "and a block is provided" do
        let(:query_param_encoder) { ->(query) { query.values.join(",") } }

        it "encodes the query string using that block" do
          expect(subject.url).to eq "/api/users/#{values[:id]}?foo,bar"
        end
      end
    end
  end
end
