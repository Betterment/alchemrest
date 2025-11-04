# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Client::Configuration do
  subject { described_class.new }

  describe "#ready?" do
    context "when frozen" do
      before do
        subject.connection.url = "https://test.com"
        subject.use_circuit_breaker(true)
        subject.use_kill_switch(true)
        subject.freeze
      end

      it { expect(subject.ready?).to eq(true) }
    end

    context "when not frozen" do
      it { expect(subject.ready?).to eq(false) }
    end
  end

  describe "#use_circuit_breaker" do
    before do
      subject.connection.url = "http://test.com"
    end

    context "(true) with service name defined" do
      before do
        subject.service_name = "acme_api"
      end

      it "sets the default circuit breaker" do
        subject.use_circuit_breaker(true)
        expect(subject.circuit_breaker).to be_instance_of(Alchemrest::CircuitBreaker)
        expect(subject.circuit_breaker.service_name).to eq('acme_api')
        expect(subject.circuit_breaker.sleep_window).to eq(90)
        expect(subject.circuit_breaker.time_window).to eq(60)
        expect(subject.circuit_breaker.volume_threshold).to eq(5)
        expect(subject.circuit_breaker.error_threshold).to eq(50)
        expect(subject.circuit_breaker.enabled?).to eq(true)
      end
    end

    context "(true) with no service name defined but a connection url defined" do
      it "sets the default circuit breaker with a random uuid for the service name" do
        subject.use_circuit_breaker(true)

        expect(subject.circuit_breaker).to be_instance_of(Alchemrest::CircuitBreaker)
        expect(subject.circuit_breaker.service_name).to match("test.com")
        expect(subject.circuit_breaker.sleep_window).to eq(90)
        expect(subject.circuit_breaker.time_window).to eq(60)
        expect(subject.circuit_breaker.volume_threshold).to eq(5)
        expect(subject.circuit_breaker.error_threshold).to eq(50)
        expect(subject.circuit_breaker.enabled?).to eq(true)
      end
    end

    context "(true) with no service name or connection url defined" do
      before do
        subject.connection.url = nil
      end

      it "raises" do
        expect { subject.use_circuit_breaker(true) }
          .to raise_error(
            Alchemrest::InvalidConfigurationError,
            "You must set `config.service_name` or `config.connection.url` before trying to use circuit breakers or kill switches",
          )
      end
    end

    context "(nil)" do
      it "sets the default circuit breaker" do
        subject.use_circuit_breaker
        expect(subject.circuit_breaker).to be_instance_of(Alchemrest::CircuitBreaker)
        expect(subject.circuit_breaker.sleep_window).to eq(90)
        expect(subject.circuit_breaker.time_window).to eq(60)
        expect(subject.circuit_breaker.volume_threshold).to eq(5)
        expect(subject.circuit_breaker.error_threshold).to eq(50)
        expect(subject.circuit_breaker.enabled?).to eq(true)
      end
    end

    context "(false)" do
      it "sets a disabled circuit breaker" do
        subject.use_circuit_breaker(false)
        expect(subject.circuit_breaker).to be_instance_of(Alchemrest::CircuitBreaker)
        expect(subject.circuit_breaker.enabled?).to be(false)
      end
    end

    context "(Hash)" do
      it "passes options hash to circuit breaker" do
        toggle = false

        subject.use_circuit_breaker(
          sleep_window: 40,
          time_window: 30,
          volume_threshold: 3,
          error_threshold: 50,
          disabled_when: -> { toggle },
        )

        expect(subject.circuit_breaker).to be_instance_of(Alchemrest::CircuitBreaker)
        expect(subject.circuit_breaker.sleep_window).to eq(40)
        expect(subject.circuit_breaker.time_window).to eq(30)
        expect(subject.circuit_breaker.volume_threshold).to eq(3)
        expect(subject.circuit_breaker.error_threshold).to eq(50)
        expect(subject.circuit_breaker.enabled?).to be(true)

        toggle = true

        expect(subject.circuit_breaker.enabled?).to be(false)
      end
    end

    context "(circuit_breaker)" do
      let(:breaker) do
        Alchemrest::CircuitBreaker.new(service_name: 'foo')
      end

      it "directly sets the circuit breaker" do
        subject.use_circuit_breaker(breaker)

        expect(subject.circuit_breaker).to eq(breaker)
      end
    end

    context "when it's already been called" do
      before { subject.use_circuit_breaker(false) }

      it "raises" do
        expect { subject.use_circuit_breaker(true) }
          .to raise_error Alchemrest::InvalidConfigurationError, "already called `use_circuit_breaker`"
      end
    end
  end

  describe "#use_kill_switch" do
    before do
      subject.connection.url = "http://test.com"
    end

    context "(true)" do
      it 'enables the kill switch' do
        subject.use_kill_switch(true)
        expect(subject.kill_switch_enabled?).to eq(true)
        expect(subject.service_name).to eq("test.com")
      end
    end

    context "(false)" do
      it 'disables the kill switch' do
        subject.use_kill_switch(false)
        expect(subject.kill_switch_enabled?).to eq(false)
        expect(subject.service_name).to eq("test.com")
      end
    end

    context "(nil)" do
      it "enalbes the kill switch" do
        subject.use_kill_switch
        expect(subject.kill_switch_enabled?).to eq(true)
        expect(subject.service_name).to eq("test.com")
      end
    end

    context "when an explicit service name is set" do
      before do
        subject.service_name = "test_api"
      end

      it 'disables the kill switch' do
        subject.use_kill_switch(false)
        expect(subject.kill_switch_enabled?).to eq(false)
        expect(subject.service_name).to eq("test_api")
      end
    end

    context "when it's already been called" do
      before { subject.use_kill_switch(false) }

      it "raises" do
        expect { subject.use_kill_switch(true) }
          .to raise_error Alchemrest::InvalidConfigurationError, "already called `use_kill_switch`"
      end
    end
  end

  describe "#freeze!" do
    context "when we've set a connection url and no service name" do
      before do
        subject.connection.url = "https://test.com"
      end

      it "let's us freeze successfully and freezes the connection configuration and sets the service name to the host name" do
        expect { subject.freeze }
          .to change { subject.connection.frozen? }.from(false).to(true)
          .and change { subject.service_name }.from(nil).to("test.com")
      end
    end

    context "when we've set a connection url and a service name" do
      before do
        subject.connection.url = "https://test.com"
        subject.service_name = 'test_api'
        subject.use_kill_switch(true)
        subject.use_circuit_breaker(true)
      end

      it "let's us freeze successfully and freezes the connection configuration" do
        expect { subject.freeze }
          .to change { subject.connection.frozen? }.from(false).to(true)
          .and not_change { subject.service_name }.from("test_api")
      end
    end

    context "when we haven't set a connection url" do
      it "raises when we try to freeze" do
        expect { subject.freeze }.to raise_error Alchemrest::InvalidConfigurationError, "No url provided"
      end
    end

    context "when we do configure a circuit breaker and kill switch" do
      before do
        subject.connection.url = "https://test.com"
        subject.use_circuit_breaker(true)
        subject.use_kill_switch(true)
      end

      it "creates a disabled circuit breaker and fires no deprecation warning" do
        subject.freeze

        expect(subject.circuit_breaker.enabled?).to eq(true)

        expect(subject.kill_switch_enabled?).to eq(true)
        expect(subject).to be_frozen
        expect(subject.ready?).to be true
      end
    end

    context "when do not explicitly configure the circuit breaker" do
      before do
        subject.connection.url = "https://test.com"
        subject.use_kill_switch(true)
      end

      it "creates a disabled circuit breaker" do
        subject.freeze

        expect(subject.circuit_breaker.enabled?).to eq(true)
        expect(subject.circuit_breaker.service_name).to match("test.com")
        expect(subject).to be_frozen
        expect(subject.ready?).to be true
      end
    end

    context "when do not explicitly configure the kill switch" do
      before do
        subject.connection.url = "https://test.com"
        subject.use_circuit_breaker(true)
      end

      it "creates a default enabled kill switch" do
        subject.freeze

        expect(subject.kill_switch_enabled?).to eq(true)
        expect(subject).to be_frozen
        expect(subject.ready?).to be true
      end
    end
  end
end
