# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::UrlBuilder::Options do
  subject { described_class.new }

  describe "#encode_query_with=" do
    context "with :rack" do
      it "sets the query param encoder correctly" do
        subject.encode_query_with = :rack
        expect(subject.query_param_encoder).to be_an_instance_of(Alchemrest::UrlBuilder::Encoders::RackEncoded)
      end
    end

    context "with :form" do
      it "sets the query param encoder correctly" do
        subject.encode_query_with = :form
        expect(subject.query_param_encoder).to be_an_instance_of(Alchemrest::UrlBuilder::Encoders::FormUrlEncoded)
      end
    end
    context "with unknown value" do
      it "sets raises" do
        expect { subject.encode_query_with = :rails }
          .to raise_error(described_class::InvalidEncoderError,
            ":rails is not a known query string encoder type. Known types are :rack and :form")
      end
    end
  end

  describe "#encode_query_with { ... }" do
    it "creates a custom encoder wrapping the block" do
      subject.encode_query_with do |query|
        query.values.join(",")
      end
      expect(subject.query_param_encoder).to be_an_instance_of(Alchemrest::UrlBuilder::Encoders::Custom)
      expect(subject.query_param_encoder.call({ foo: "bar" })).to eq("bar")
    end
  end

  describe "#create_builder" do
    context "with values, query params, and the rack encoder" do
      it "creates the url builder with the right options set" do
        subject.values = { id: SecureRandom.uuid }
        subject.query = { names: %w(test foo) }
        subject.encode_query_with = :rack
        builder = subject.create_builder(template: '/api/users/:id')

        expect(builder).to be_an_instance_of(Alchemrest::UrlBuilder)
        expect(builder.values).to eq(subject.values)
        expect(builder.query).to eq(subject.query)
        expect(builder.query_param_encoder).to be_an_instance_of(Alchemrest::UrlBuilder::Encoders::RackEncoded)
      end
    end

    context "with values only" do
      it "creates the url builder with the right options set" do
        subject.values = { id: SecureRandom.uuid }
        builder = subject.create_builder(template: '/api/users/:id')

        expect(builder).to be_an_instance_of(Alchemrest::UrlBuilder)
        expect(builder.values).to eq(subject.values)
      end
    end

    context "with values and query params" do
      it "creates the url builder with the right options set" do
        subject.values = { id: SecureRandom.uuid }
        subject.query = { names: %w(test foo) }
        builder = subject.create_builder(template: '/api/users/:id')

        expect(builder).to be_an_instance_of(Alchemrest::UrlBuilder)
        expect(builder.values).to eq(subject.values)
        expect(builder.query).to eq(subject.query)
      end
    end

    context "with query params only" do
      it "creates the url builder with the right options set" do
        subject.query = { names: %w(test foo) }
        builder = subject.create_builder(template: '/api/users/')

        expect(builder).to be_an_instance_of(Alchemrest::UrlBuilder)
        expect(builder.query).to eq(subject.query)
      end
    end
  end
end
