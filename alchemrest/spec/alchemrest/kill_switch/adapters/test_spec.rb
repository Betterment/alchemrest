# frozen_string_literal: true

RSpec.describe Alchemrest::KillSwitch::Adapters::Test do
  include_examples 'Alchemrest::KillSwitch::Adapters'

  describe '#ready?' do
    subject { described_class.new }

    it 'returns true' do
      expect(subject.ready?).to eq(true)
    end
  end
end
