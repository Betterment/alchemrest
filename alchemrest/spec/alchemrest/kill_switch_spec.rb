# frozen_string_literal: true

require 'spec_helper'

def with_kill_switch_adapter(adapter)
  original = Alchemrest.kill_switch_adapter
  Alchemrest.kill_switch_adapter = adapter
  yield
ensure
  Alchemrest.kill_switch_adapter = original
end

RSpec.describe Alchemrest::KillSwitch do
  it 'defaults kill_switch_adapter to ActiveRecord' do
    with_kill_switch_adapter(nil) do
      expect(Alchemrest.kill_switch_adapter).to be_a(Alchemrest::KillSwitch::Adapters::ActiveRecord)
    end
  end

  describe '.new' do
    let(:service_name) { 'bank' }

    def apply
      described_class.new(service_name:)
    end

    it 'returns a new instance' do
      expect(apply).to be_a(described_class)
    end

    it 'sets the #service_name' do
      expect(apply.service_name).to eq(service_name)
    end

    context 'when service_name is nil' do
      let(:service_name) { nil }

      it 'raises an error' do
        expect { apply }.to raise_error(ArgumentError, 'service_name is required')
      end
    end
  end

  describe '#active?' do
    let(:service_name) { 'bank' }
    let(:adapter) { instance_double(described_class::Adapters::Test) }

    subject { described_class.new(service_name:) }

    def apply
      subject.active?
    end

    around(:each) do |ex|
      with_kill_switch_adapter(adapter) { ex.run }
    end

    it 'returns proxies to the adapter' do
      result = true
      allow(adapter).to receive(:active?).and_return(result)

      expect(apply).to eq(result)
      expect(adapter).to have_received(:active?).with(service_name:)
    end
  end

  describe '#activate!' do
    let(:service_name) { 'bank' }
    let(:adapter) { instance_double(described_class::Adapters::Test) }

    subject { described_class.new(service_name:) }

    def apply
      subject.activate!
    end

    around(:each) do |ex|
      with_kill_switch_adapter(adapter) { ex.run }
    end

    it 'returns proxies to the adapter' do
      result = true
      allow(adapter).to receive(:activate).and_return(result)

      expect(apply).to eq(result)
      expect(adapter).to have_received(:activate).with(service_name:)
    end
  end

  describe '#deactivate!' do
    let(:service_name) { 'bank' }
    let(:adapter) { instance_double(described_class::Adapters::Test) }

    subject { described_class.new(service_name:) }

    def apply
      subject.deactivate!
    end

    around(:each) do |ex|
      with_kill_switch_adapter(adapter) { ex.run }
    end

    it 'returns proxies to the adapter' do
      result = true
      allow(adapter).to receive(:deactivate).and_return(result)

      expect(apply).to eq(result)
      expect(adapter).to have_received(:deactivate).with(service_name:)
    end
  end
end
