# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Response do
  let(:raw_response) do
    instance_double(
      Faraday::Response,
      status:,
      success?: success,
      body:,
    )
  end

  let(:error_details) { nil }

  subject { described_class.new(raw_response) }

  describe "#server_error?" do
    context "when a 503 status code" do
      let(:status) { 503 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.server_error?).to be true
      end
    end

    context "when a 200 status code" do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.server_error?).to be false
      end
    end

    context "when a 403 status code" do
      let(:status) { 403 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.server_error?).to be false
      end
    end
  end

  describe "#client_error?" do
    context "when a 500 status code" do
      let(:status) { 500 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.client_error?).to be false
      end
    end

    context "when a 200 status code" do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.client_error?).to be false
      end
    end

    context "when a 399 status code" do
      let(:status) { 399 }
      let(:success) { true }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.client_error?).to be false
      end
    end

    context "when a 400 status code" do
      let(:status) { 400 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.client_error?).to be true
      end
    end

    context "when a 499 status code" do
      let(:status) { 499 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.client_error?).to be true
      end
    end
  end

  describe "#auth_error?" do
    context "when a 503 status code" do
      let(:status) { 503 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.auth_error?).to be false
      end
    end

    context "when a 200 status code" do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.auth_error?).to be false
      end
    end

    context "when a 400 status code" do
      let(:status) { 400 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.auth_error?).to be false
      end
    end

    context "when a 401 status code" do
      let(:status) { 401 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.auth_error?).to be true
      end
    end

    context "when a 403 status code" do
      let(:status) { 403 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.auth_error?).to be true
      end
    end
  end

  describe "#not_found_error?" do
    context "when a 503 status code" do
      let(:status) { 503 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.not_found_error?).to be false
      end
    end
    context "when a 200 status code" do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.not_found_error?).to be false
      end
    end

    context "when a 400 status code" do
      let(:status) { 400 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.not_found_error?).to be false
      end
    end

    context "when a 404 status code" do
      let(:status) { 404 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is true" do
        expect(subject.not_found_error?).to be true
      end
    end
  end

  describe "#no_content_response?" do
    let(:success) { true }
    let(:body) { '' }

    context "for a 204" do
      let(:status) { 204 }
      let(:body) { nil }

      it "returns true for a 204" do
        expect(subject.no_content_response?).to eq(true)
      end
    end

    context "for a 200" do
      let(:success) { true }
      let(:status) { 200 }
      let(:body) { 'test' }

      it "returns false" do
        expect(subject.no_content_response?).to eq(false)
      end
    end
  end

  describe "error_details" do
    context "when the request is not a success" do
      let(:status) { 503 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "has a basic error details string" do
        expect(subject.error_details).to eq("Error with HTTP status: 503")
      end
    end

    context "when the request is a success" do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { { foo: "bar" } }

      it "has a basic error details string" do
        expect(subject.error_details).to be nil
      end
    end
  end

  describe "to_result" do
    context "when a 200 status code" do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { { foo: "bar" } }

      it "is an ok result with itself as the value" do
        expect(subject.to_result).to eq Alchemrest::Result.Ok(subject)
      end
    end

    context "for any error status" do
      let(:status) { 503 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "returns an error result, and sets a backtrace on the wrapped exception" do
        expect(subject.to_result.send(:error).backtrace).not_to be_nil
      end
    end

    context "when a 503 status code" do
      let(:status) { 503 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is an error result with a server error" do
        expect(subject.to_result.send(:error)).to be_kind_of Alchemrest::ServerError
      end
    end

    context "when a 400 status code" do
      let(:status) { 400 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is an error result with a client error" do
        expect(subject.to_result.send(:error)).to be_kind_of Alchemrest::ClientError
      end
    end
    context "when a 401 status code" do
      let(:status) { 401 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is an error result with an auth error" do
        expect(subject.to_result.send(:error)).to be_kind_of Alchemrest::AuthError
      end
    end

    context "when a 404 status code" do
      let(:status) { 404 }
      let(:success) { false }
      let(:body) { { foo: "bar" } }

      it "is an error result with a not found error" do
        expect(subject.to_result.send(:error)).to be_kind_of Alchemrest::NotFoundError
      end
    end
  end

  describe "#body" do
    let(:status) { 200 }
    let(:body) { { foo: "bar" } }
    let(:success) { true }

    it "returns the body" do
      expect(subject.body).to eq(raw_response.body)
    end
  end

  describe "#status" do
    let(:status) { 200 }
    let(:body) { { foo: "bar" } }
    let(:success) { true }

    it "returns the status" do
      expect(subject.status).to eq(raw_response.status)
    end
  end

  describe '#circuit_open?' do
    let(:raw_response) { instance_double(Faraday::Response, status: 200) }

    it 'returns false' do
      expect(subject.circuit_open?).to eq false
    end
  end

  describe '#timeout?' do
    let(:raw_response) { instance_double(Faraday::Response, status: 200) }

    it 'returns false' do
      expect(subject.timeout?).to eq false
    end
  end

  describe "#request_failed?" do
    context "with a 503 response" do
      let(:raw_response) { instance_double(Faraday::Response, status: 599) }

      it 'returns false' do
        expect(subject.request_failed?).to eq true
      end
    end

    context "with a 500 response" do
      let(:raw_response) { instance_double(Faraday::Response, status: 500) }
      it 'returns false' do
        expect(subject.request_failed?).to eq true
      end
    end

    context "with a 499 response" do
      let(:raw_response) { instance_double(Faraday::Response, status: 499) }
      it 'returns false' do
        expect(subject.request_failed?).to eq false
      end
    end

    context "with a 200 response" do
      let(:raw_response) { instance_double(Faraday::Response, status: 200) }

      it 'returns false' do
        expect(subject.request_failed?).to eq false
      end
    end

    context "with a 783 response" do
      let(:raw_response) { instance_double(Faraday::Response, status: 600) }

      it 'returns false' do
        expect(subject.request_failed?).to eq false
      end
    end
  end
end
