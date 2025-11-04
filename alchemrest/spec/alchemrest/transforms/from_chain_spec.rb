# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Transforms::FromChain do
  describe 'self.number' do
    it 'returns a FromNumber transform' do
      expect(described_class.number).to be_a Alchemrest::Transforms::FromNumber
    end
  end

  describe 'self.string' do
    it 'returns a FromString transform' do
      expect(described_class.string).to be_a Alchemrest::Transforms::FromString
    end
  end
end
