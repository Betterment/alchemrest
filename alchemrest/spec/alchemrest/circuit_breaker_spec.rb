# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::CircuitBreaker do
  let(:use_circuit_breaker) { true }
  let(:disable_circuit) { false }

  let(:failed_result) do
    Alchemrest::Result::Error(
      Alchemrest::RequestFailedError.new(
        Faraday::SSLError.new(OpenSSL::SSL::SSLError.new),
      ),
    )
  end

  let(:server_error_result) do
    raw_response = instance_double(
      Faraday::Response,
      status: 503,
      success?: false,
      body: nil,
    )

    Alchemrest::Result::Error(
      Alchemrest::ServerError.new(Alchemrest::Response.new(raw_response)),
    )
  end

  let(:good_result) do
    Alchemrest::Result::Ok("good")
  end

  before do
    Circuitbox.configure do |config|
      config.default_circuit_store = Moneta.new(:Memory, expires: true)
    end
  end

  let(:sleep_window) { 2 }
  let(:time_window) { 1 }
  let(:error_threshold) { 60 }
  let(:volume_threshold) { 4 }
  let(:service_name) { "test-#{SecureRandom.uuid}" }

  subject { described_class.new(service_name:, sleep_window:, volume_threshold:, error_threshold:, time_window:) }

  describe ".new" do
    it "initializes the circuit box with the right options and creates a working circuit breaker" do
      expect(Circuitbox).to receive(:circuit).with(
        service_name,
        hash_including(sleep_window:, time_window:, volume_threshold:, error_threshold:),
      ).and_call_original

      expect(subject.open?).to eq(false)
      subject.monitor!(result: failed_result)
      subject.monitor!(result: failed_result)
      subject.monitor!(result: failed_result)
      subject.monitor!(result: failed_result)
      expect(subject.open?).to eq(true)
    end

    context "when you use only default options" do
      subject { described_class.new(service_name:) }

      let(:expected_options) do
        {
          sleep_window: 90,
          time_window: 60,
          volume_threshold: 5,
          error_threshold: 50,
        }
      end

      it "initializes the circuit box with the right options creates a usable circuit breaker" do
        expect(Circuitbox).to receive(:circuit).with(
          service_name,
          hash_including(expected_options),
        ).and_call_original

        expect(subject.open?).to eq(false)
        subject.monitor!(result: failed_result)
      end
    end

    context "the circuit restores itself after the sleep window" do
      let(:now) { Time.zone.parse('2021-1-1') }

      it "restores the circuit" do
        expect(subject.open?).to eq(false)

        Timecop.freeze(now) do
          subject.monitor!(result: good_result)
          subject.monitor!(result: failed_result)
          subject.monitor!(result: failed_result)
          subject.monitor!(result: failed_result)
          expect(subject.open?).to eq(true)
        end

        Timecop.freeze(now + (sleep_window + 1)) do
          expect(subject.open?).to eq(false)
        end
      end
    end

    context "the circuit remains open during the sleep window" do
      let(:now) { Time.zone.parse('2021-1-1') }

      it "restores the circuit" do
        expect(subject.open?).to eq(false)

        Timecop.freeze(now) do
          subject.monitor!(result: good_result)
          subject.monitor!(result: failed_result)
          subject.monitor!(result: failed_result)
          subject.monitor!(result: failed_result)
          expect(subject.open?).to eq(true)
        end

        Timecop.freeze(now + (sleep_window - 1)) do
          expect(subject.open?).to eq(true)
        end
      end
    end
  end

  describe "#enabled?" do
    context 'when service_name is nil' do
      let(:service_name) { nil }

      it 'returns false' do
        expect(subject.enabled?).to eq(false)
      end
    end

    context 'when `disabled_when:` evaluates to true' do
      subject { described_class.new(service_name:, disabled_when: -> { true }) }

      it 'returns true' do
        expect(subject.enabled?).to eq(false)
      end
    end

    context 'when `disabled_when:` evaluates to false' do
      subject { described_class.new(service_name:, disabled_when: -> { false }) }

      it 'returns true' do
        expect(subject.enabled?).to eq(true)
      end
    end

    context 'when `disabled_when:` is not passed' do
      subject { described_class.new(service_name:) }

      it 'returns true' do
        expect(subject.enabled?).to eq(true)
      end
    end
  end

  describe "#open?" do
    let(:open) { false }

    let(:breaker) { instance_double(Circuitbox::CircuitBreaker, open?: open) }

    before do
      allow(Circuitbox).to receive(:circuit).and_return(breaker)
    end

    context "when the circuit box circuit is open" do
      let(:open) { true }

      it "returns true" do
        expect(subject.open?).to eq(true)
      end
    end

    context "when the circuit box circuit is closed" do
      let(:open) { false }

      it "returns false" do
        expect(subject.open?).to eq(false)
      end
    end

    context "when the circuit breaker is not enabled" do
      subject { described_class.new(service_name:, disabled_when: -> { true }) }
      let(:open) { true }

      it "returns false" do
        expect(subject.open?).to eq(false)
      end
    end
  end

  describe "#monitor!" do
    context "when we monitor a good request" do
      it "returns success" do
        expect(subject.monitor!(result: good_result)).to eq(:success)
      end
    end

    context "when we monitor a failed request" do
      it "returns failure" do
        expect(subject.monitor!(result: failed_result)).to eq(:failure)
      end
    end

    context "when we see enough failed requests to trip the circuit" do
      it "trips the circuit" do
        expect(subject.open?).to eq(false)
        subject.monitor!(result: good_result)
        subject.monitor!(result: failed_result)
        subject.monitor!(result: failed_result)
        subject.monitor!(result: failed_result)
        expect(subject.open?).to eq(true)
      end
    end

    context "when we see enough server errors to trip the circuit" do
      it "trips the circuit" do
        expect(subject.open?).to eq(false)
        subject.monitor!(result: good_result)
        subject.monitor!(result: server_error_result)
        subject.monitor!(result: server_error_result)
        subject.monitor!(result: server_error_result)
        expect(subject.open?).to eq(true)
      end
    end

    context "when we see enough mixed failures to trip the circuit" do
      it "opens the circuit" do
        expect(subject.open?).to eq(false)
        subject.monitor!(result: good_result)
        subject.monitor!(result: failed_result)
        subject.monitor!(result: server_error_result)
        subject.monitor!(result: failed_result)
        expect(subject.open?).to eq(true)
      end
    end

    context "when we don't see enough errors to trip the circuit" do
      it "doesn't trip the circuit" do
        expect(subject.open?).to eq(false)
        subject.monitor!(result: good_result)
        subject.monitor!(result: failed_result)
        subject.monitor!(result: good_result)
        subject.monitor!(result: good_result)
        expect(subject.open?).to eq(false)
      end
    end

    context "when the breaker is not enabled" do
      subject { described_class.new(service_name:, disabled_when: -> { true }) }

      it "returns nil" do
        expect(subject.monitor!(result: failed_result)).to eq(nil)
      end
    end
  end
end
