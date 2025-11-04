# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Sentry do
  let(:identifier) { "GET /api/v1/payment_requests" }
  let(:response_data) { { key: "value" } }
  let(:result) { Alchemrest::Result::Ok(response_data) }

  around do |example|
    setup_sentry_test
    example.run
    teardown_sentry_test
  end

  let(:existing_contexts) { nil }

  before do
    (existing_contexts || {}).each do |key, value|
      Sentry.set_context(key, value)
    end
  end

  describe ".capture_response" do
    context "when we get an alchemrest error" do
      let(:result) { Alchemrest::Result::Error("error") }

      it "adds error to context" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ error: "error" })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when an existing response is already captured for the same identifier" do
      let(:existing_contexts) { { identifier => { responses: [{ foo: "bar" }] } } }

      it "adds data to context" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(2)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].last).to eq({ data: response_data })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when response data size is greater than 6kb" do
      # JOSN boilerplate adds 10 bytes
      let(:response_data) { { key: "a" * 5991 } }

      it "replaces data with filtered message" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ warning: "[FILTERED FOR SIZE]" })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when response data size is less than or equal to 6kb" do
      # JOSN boilerplate adds 10 bytes
      let(:response_data) { { key: "a" * 5990 } }

      it "replaces data with filtered message" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ data: response_data })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when current sentry context size is <= 12" do
      # Sentry has 2 contexts by default, so we need to add 10 more
      let(:existing_contexts) { Array.new(10).to_h { |_| [SecureRandom.uuid, {}] } }

      it "adds data to context" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ data: response_data })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when context size is greater than 12" do
      # Sentry has 2 contexts by default, so we need to add 11 more
      let(:existing_contexts) { Array.new(11).to_h { |_| [SecureRandom.uuid, {}] } }

      it "replaces data with 'TOO MANY RESPONSES'" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ warning: "[TOO MANY RESPONSES]" })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when sentry context size is 16" do
      # Sentry has 2 contexts by default, so we need to add 14 more
      let(:existing_contexts) { Array.new(14).to_h { |_| [SecureRandom.uuid, {}] } }

      it "replaces data with 'TOO MANY RESPONSES'" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ warning: "[TOO MANY RESPONSES]" })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when current sentry context size is > 16" do
      # Sentry has 2 contexts by default, so we need to add 10 more
      let(:existing_contexts) { Array.new(15).to_h { |_| [SecureRandom.uuid, {}] } }

      it "does not add data to context" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier]).to be_nil
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to be_nil
      end
    end

    context "when the existing number of captured responses is <= 12" do
      let(:existing_contexts) { Array.new(6).to_h { |_| [SecureRandom.uuid, { responses: [{ foo: "bar" }, { foo: "bar" }] }] } }

      it "adds data to context" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ data: response_data })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when the existing number of captured responses is greater than 12" do
      let(:existing_contexts) do
        Array.new(6).to_h { |_| [SecureRandom.uuid, { responses: [{ foo: "bar" }, { foo: "bar" }] }] }
          .merge(extra: { responses: [{ foo: "bar" }] })
      end

      it "replaces data with 'TOO MANY RESPONSES'" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ warning: "[TOO MANY RESPONSES]" })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when the existing number of captured responses is 16" do
      let(:existing_contexts) { Array.new(8).to_h { |_| [SecureRandom.uuid, { responses: [{ foo: "bar" }, { foo: "bar" }] }] } }

      it "replaces data with 'TOO MANY RESPONSES'" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier][:responses].size).to eq(1)
        expect(Sentry.get_current_scope.contexts[identifier][:responses].sole).to eq({ warning: "[TOO MANY RESPONSES]" })
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to eq(true)
      end
    end

    context "when the existing number of captured responses is > 16" do
      let(:existing_contexts) do
        Array.new(8).to_h { |_| [SecureRandom.uuid, { responses: [{ foo: "bar" }, { foo: "bar" }] }] }
          .merge(extra: { responses: [{ foo: "bar" }] })
      end

      it "does not add data to context" do
        described_class.capture_response(identifier:, result:)

        expect(Sentry.get_current_scope.contexts[identifier]).to be_nil
        expect(Sentry.get_current_scope.tags[:includes_captured_alchemrest_response]).to be_nil
      end
    end
  end
end
