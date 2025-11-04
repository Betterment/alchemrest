# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "docs/working_with_kill_switches_and_circuit_breakers" do
  let(:root) { BankApi::Root.new(id: 1) }

  after do
    BankApi::Client.kill_switch.deactivate!
  end

  let!(:api_request) do
    stub_alchemrest_request(root.build_request(:get_user))
      .to_return(
        status: 200,
        body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
      )
  end

  def expect_success
    result = root.get_user
    name, error = case result
                    in Alchemrest::Result::Ok(user)
                      [user.name, nil]
                    in Alchemrest::Result::Error({status: 404})
                      [nil, "User not found"]
                    else
                      result.unwrap_or_rescue { [nil, "Uh Oh"] }
                  end

    expect(name).to eq("Kevin")
    expect(error).to eq(nil)
    expect(rescued_exceptions.count).to eq(0)
  end

  def expect_kill_switch_failure
    result = root.get_user
    name, error = case result
                    in Alchemrest::Result::Ok(data => user)
                      [user.name, nil]
                    in Alchemrest::Result::Error(Alchemrest::KillSwitchEnabledError)
                      [nil, "Doh! The Kill Switch is on"]
                    else
                      result.unwrap_or_rescue { [nil, "Uh Oh"] }
                  end

    expect(error).to eq("Doh! The Kill Switch is on")
    expect(name).to eq(nil)
    expect(rescued_exceptions.count).to eq(0)
  end

  describe "working with kill switches" do
    it "respects the current state of the kill switch" do
      expect_success
      BankApi::Client.kill_switch.activate!
      expect_kill_switch_failure
      BankApi::Client.kill_switch.deactivate!
      expect_success
    end
  end

  describe "working with circuit breakers" do
    before do
      Circuitbox.configure do |config|
        config.default_circuit_store = Moneta.new(:Memory, expires: true)
      end
    end

    context "with testable configuration" do
      before do
        BankApi::Client.configure do |config|
          config.connection.url = 'http://bank.example.com'
          config.service_name = "bank"
          config.use_kill_switch(true)
          config.use_circuit_breaker(volume_threshold: 3, sleep_window: 2, time_window: 1)
          config.connection.customize do |c|
            c.options[:open_timeout] = 4
            c.options[:timeout] = 10
          end
        end
      end

      let!(:api_request) do
        stub_alchemrest_request(root.build_request(:get_user))
          .to_return(
            status: 503,
          )
      end

      it "triggers the circuit breaker when the service is down" do
        root.get_user => { error: server_error }

        5.times.each { root.get_user }

        root.get_user => { error: circuit_open_error }

        expect(circuit_open_error).to be_instance_of(Alchemrest::CircuitOpenError)
        expect(server_error).to be_instance_of(Alchemrest::ServerError)
      end
    end

    context "with a sample customized configuration" do
      before do
        BankApi::Client.configure do |config|
          config.connection.url = 'http://bank.example.com'
          config.service_name = "bank"
          config.use_kill_switch(true)
          config.use_circuit_breaker(
            sleep_window: 60,
            time_window: 30,
            volume_threshold: 3,
            error_threshold: 50,
            disabled_when: -> { ENV.fetch('TEST', nil) },
          )
        end
      end

      it "sets up a valid circuit_breaker" do
        expect(BankApi::Client.configuration.circuit_breaker.sleep_window).to eq(60)
        expect(BankApi::Client.configuration.circuit_breaker.time_window).to eq(30)
        expect(BankApi::Client.configuration.circuit_breaker.volume_threshold).to eq(3)
        expect(BankApi::Client.configuration.circuit_breaker.error_threshold).to eq(50)
        expect(BankApi::Client.configuration.circuit_breaker.enabled?).to eq(true)

        ENV["TEST"] = "true"

        expect(BankApi::Client.configuration.circuit_breaker.enabled?).to eq(false)

        ENV["TEST"] = nil
      end
    end

    context "with a sample customized configuration with only some options" do
      before do
        BankApi::Client.configure do |config|
          config.connection.url = 'http://bank.example.com'
          config.service_name = "bank"
          config.use_kill_switch(true)
          config.use_circuit_breaker(
            disabled_when: -> { ENV.fetch('TEST', nil) },
          )
        end
      end

      it "sets up a valid circuit_breaker" do
        expect(BankApi::Client.configuration.circuit_breaker.enabled?).to eq(true)

        ENV["TEST"] = "true"

        expect(BankApi::Client.configuration.circuit_breaker.enabled?).to eq(false)

        ENV["TEST"] = nil
      end
    end

    context "with an uncustomized configuration" do
      before do
        BankApi::Client.configure do |config|
          config.connection.url = 'http://bank.example.com'
          config.service_name = "bank"
          config.use_kill_switch(true)
          config.use_circuit_breaker(true)
        end
      end

      it "sets up a valid circuit_breaker" do
        expect(BankApi::Client.configuration.circuit_breaker.enabled?).to eq(true)
      end
    end

    context "with a disabled configuration" do
      before do
        BankApi::Client.configure do |config|
          config.connection.url = 'http://bank.example.com'
          config.service_name = "bank"
          config.use_kill_switch(true)
          config.use_circuit_breaker(false)
        end
      end

      it "sets up a valid circuit_breaker" do
        expect(BankApi::Client.configuration.circuit_breaker.enabled?).to eq(false)
      end
    end

    context "with a custom circuit breaker" do
      let(:custom_circuit_breaker) do
        klass = Class.new(Alchemrest::CircuitBreaker) do
          def request_failed?(*) = true
        end

        klass.new(service_name: "bank", volume_threshold: 3, sleep_window: 2, time_window: 1)
      end

      let!(:api_request) do
        stub_alchemrest_request(root.build_request(:get_user))
          .to_return(
            status: 200,
            body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
          )
      end

      before do
        breaker = custom_circuit_breaker

        BankApi::Client.configure do |config|
          config.connection.url = 'http://bank.example.com'
          config.service_name = "bank"
          config.use_kill_switch(true)
          config.use_circuit_breaker(breaker)
        end
      end

      it "sets up a valid circuit_breaker which trips for any request" do
        expect(BankApi::Client.configuration.circuit_breaker.enabled?).to eq(true)

        root.get_user => { value: user }

        5.times.each { root.get_user }

        root.get_user => { error: circuit_open_error }
      end
    end
  end
end
