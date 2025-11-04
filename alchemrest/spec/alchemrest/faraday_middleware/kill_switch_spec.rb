# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::FaradayMiddleware::KillSwitch do
  let(:service_name) { 'something' }
  let(:kill_switch) { Alchemrest::KillSwitch.new(service_name:) }
  let(:options) { { service_name: } }
  let(:app) { ->(env) {} }
  subject { described_class.new(app, options) }

  describe '.new' do
    it 'raises if service_name option is missing' do
      expect { described_class.new(->(env) {}) }.to raise_error(KeyError, 'key not found: :service_name')
    end

    it 'constructs' do
      expect(subject).to be_a(described_class)
    end

    it 'sets the app' do
      expect(described_class.new(app, options).app).to eq(app)
    end

    it 'sets the service_name' do
      expect(described_class.new(app, options).service_name).to eq(service_name)
    end
  end

  describe '#call' do
    context 'when the kill switch is active' do
      before do
        kill_switch.activate!
      end

      it 'raises' do
        env = {}
        expect { subject.call(env) }.to raise_error(Alchemrest::KillSwitchEnabledError)
      end
    end

    context 'when the kill switch is inactive' do
      before do
        kill_switch.deactivate!
      end

      it 'calls the app' do
        allow(app).to receive(:call).and_call_original
        env = {}
        subject.call(env)
        expect(app).to have_received(:call).with(env)
      end
    end
  end
end
