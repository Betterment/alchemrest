# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::EndpointDefinition do
  subject { described_class.new(template:, http_method:, builder_block:) }
  let(:template) { "/api/users/:id" }
  let(:http_method) { "get" }
  let(:builder_block) { lambda { |url| url.values = { id: user_id } } }

  describe "self.new" do
    context "with a valid template, method, and builder_block" do
      it "does not throw an error" do
        expect(subject).to be_a(described_class)
      end
    end

    context "with an upcased method" do
      let(:http_method) { "GET" }

      it "does not throw an error" do
        expect(subject).to be_a(described_class)
      end
    end

    context "with a non-string template" do
      let(:template) { 123 }

      it "throws an error" do
        expect { subject }.to raise_error(ArgumentError, "template must be string")
      end
    end

    context "with an empty template" do
      let(:template) { "" }
      it "throws an error" do
        expect { subject }.to raise_error(ArgumentError, "missing template")
      end
    end

    context "with an invalid HTTP method" do
      let(:http_method) { "invalid" }
      it "throws an error" do
        expect { subject }.to raise_error(ArgumentError, "must provide a valid HTTP method")
      end
    end
  end

  describe "#url_for" do
    let(:user_id) { SecureRandom.uuid }
    let(:context) { Struct.new(:user_id).new(user_id) }

    context "with a template and a builder block" do
      it "returns the correct URL" do
        expect(subject.url_for(context)).to eq "/api/users/#{user_id}"
      end
    end

    context "with a template and no builder block" do
      let(:builder_block) { nil }

      it "returns the correct URL" do
        expect(subject.url_for(context)).to eq "/api/users/:id"
      end
    end
  end
end
