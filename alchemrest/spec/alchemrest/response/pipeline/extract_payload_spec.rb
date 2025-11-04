# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Response::Pipeline::ExtractPayload do
  let(:path_to_payload) { nil }
  let(:allow_empty_response) { false }
  let(:status) { 200 }
  let(:response) do
    Alchemrest::Response.new(
      instance_double(Faraday::Response, body:, env:, status:),
    )
  end
  let(:body) { { "data" => { "user" => { "name" => "John" } } } }
  let(:env) do
    Faraday::Env.new.tap do |e|
      e.method = :get
      e.url = URI("https://example.com")
    end
  end

  subject { described_class.new(path_to_payload, allow_empty_response) }

  describe "#initialize" do
    context "when allow empty response is not provided" do
      subject { described_class.new(path_to_payload) }

      it "defaults to false and works" do
        expect(subject).to eq(described_class.new(path_to_payload, false))
        expect(subject.allow_empty_response).to eq(false)
      end
    end

    context "when allow empty response is provided" do
      subject { described_class.new(path_to_payload, true) }

      it "uses the passed in value" do
        expect(subject).to eq(described_class.new(path_to_payload, true))
        expect(subject.allow_empty_response).to eq(true)
      end
    end

    context "when path to payload is not provided" do
      subject { described_class.new }

      it "defaults allow_empty_response to false and accepts nil path_to_payload" do
        expect(subject).to eq(described_class.new(path_to_payload, false))
        expect(subject.path_to_payload).to eq(nil)
      end
    end

    context "when path_to_payload is provided" do
      subject { described_class.new("test") }

      it "defaults allow_empty_response to false and accepts passed value for path_to_payload" do
        expect(subject).to eq(described_class.new("test"))
        expect(subject.path_to_payload).to eq("test")
      end
    end
  end

  describe "#call" do
    context "when path_to_payload is nil" do
      let(:path_to_payload) { nil }

      it "returns the whole body" do
        expect(subject.call(response).from_right).to eq(body)
      end
    end

    context "when path_to_payload set" do
      let(:path_to_payload) { %i(data user) }

      it "returns the portion of the body" do
        expect(subject.call(response).from_right).to eq({ "name" => "John" })
      end

      context "when the hash doesn't match the structured expected by path to payload" do
        let(:body) { { "data" => { "name" => "John" } } }

        it "returns an error result" do
          error = subject.call(response).from_left
          expect(error).to be_a(Alchemrest::ResponsePipelineError)
          expect(error.message).to eq("Response body did not contain expected payload at #{path_to_payload}")
        end
      end

      context "when the hash has a scalar along the path" do
        let(:body) { { "data" => 1 } }

        it "returns an error result" do
          error = subject.call(response).from_left
          expect(error).to be_a(Alchemrest::ResponsePipelineError)
          expect(error.message).to eq("Response body did not contain expected payload at #{path_to_payload}")
        end
      end

      context "when we want to drill into an array" do
        let(:body) { { "data" => ["User", { "name" => "John" }] } }
        let(:path_to_payload) { [:data, 1] }

        it "returns the portion of the body" do
          expect(subject.call(response).from_right).to eq({ "name" => "John" })
        end
      end
    end

    context "when allow empty response is false" do
      context 'when given an empty response' do
        let(:body) { '' }
        let(:status) { 204 }

        it "errors" do
          error = subject.call(response).from_left
          expect(error).to be_a(Alchemrest::ResponsePipelineError)
          expect(error.message).to eq("Ok but empty response not allowed")
        end
      end
    end

    context "when allow empty response is true" do
      let(:allow_empty_response) { true }

      context 'when given an empty response' do
        let(:body) { '' }
        let(:status) { 204 }

        it "returns a nil" do
          expect(subject.call(response).from_right).to eq(Alchemrest::Response::Pipeline::Final.new(nil))
        end
      end

      context 'when not given an empty response' do
        it 'extracts the payload' do
          expect(subject.call(response).from_right).to eq(body)
        end
      end
    end
  end
end
