# frozen_string_literal: true

require 'securerandom'

RSpec.shared_examples 'Alchemrest::KillSwitch::Adapters' do
  describe '#active?' do
    let(:service_name) { SecureRandom.uuid }

    subject { described_class.new }

    def apply
      subject.active?(service_name:)
    end

    context 'with nil service_name' do
      let(:service_name) { nil }

      it 'raises an error' do
        expect { apply }.to raise_error(StandardError, 'service_name cannot be nil')
      end
    end

    context 'with no existing record' do
      it 'returns false' do
        expect(apply).to eq(false)
      end
    end

    context 'with an existing record set to false' do
      before do
        subject.deactivate(service_name:)
      end

      it 'returns false' do
        expect(apply).to eq(false)
      end
    end

    context 'with an existing record set to true' do
      before do
        subject.activate(service_name:)
      end

      it 'returns true' do
        expect(apply).to eq(true)
      end
    end

    context 'with multiple existing records set to different values' do
      before do
        subject.activate(service_name:)
        subject.deactivate(service_name: 'other_service_name')
      end

      it 'returns the right one' do
        expect(apply).to eq(true)
      end
    end
  end

  describe '#activate' do
    let(:service_name) { 'bank' }

    subject { described_class.new }

    def apply
      subject.activate(service_name:)
    end

    context 'with no existing record' do
      it 'sets the record to enabled' do
        apply
        expect(subject.active?(service_name:)).to eq(true)
      end
    end

    context 'with an existing record set to false' do
      before do
        subject.deactivate(service_name:)
      end

      it 'sets the record to enabled' do
        apply
        expect(subject.active?(service_name:)).to eq(true)
      end
    end

    context 'with an existing record set to true' do
      before do
        subject.activate(service_name:)
      end

      it 'sets the record to enabled' do
        apply
        expect(subject.active?(service_name:)).to eq(true)
      end
    end

    context 'with multiple existing records set to different values' do
      let(:other_service_name) { 'other_service_name' }

      before do
        subject.deactivate(service_name:)
        subject.deactivate(service_name: other_service_name)
      end

      it 'enables the proper record' do
        apply
        expect(subject.active?(service_name:)).to eq(true)
        expect(subject.active?(service_name: other_service_name)).to eq(false)
      end
    end
  end

  describe '#deactivate' do
    let(:service_name) { 'bank' }

    subject { described_class.new }

    def apply
      subject.deactivate(service_name:)
    end

    context 'with no existing record' do
      it 'sets the record to disabled' do
        apply
        expect(subject.active?(service_name:)).to eq(false)
      end
    end

    context 'with an existing record set to false' do
      before do
        subject.deactivate(service_name:)
      end

      it 'sets the record to disabled' do
        apply
        expect(subject.active?(service_name:)).to eq(false)
      end
    end

    context 'with an existing record set to true' do
      before do
        subject.activate(service_name:)
      end

      it 'sets the record to disabled' do
        apply
        expect(subject.active?(service_name:)).to eq(false)
      end
    end

    context 'with multiple existing records set to different values' do
      let(:other_service_name) { 'other_service_name' }

      before do
        subject.activate(service_name:)
        subject.activate(service_name: other_service_name)
      end

      it 'disables the proper record' do
        apply
        expect(subject.active?(service_name:)).to eq(false)
        expect(subject.active?(service_name: other_service_name)).to eq(true)
      end
    end
  end
end
