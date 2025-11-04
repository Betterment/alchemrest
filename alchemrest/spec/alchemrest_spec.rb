# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest do
  it "has a version number" do
    expect(Alchemrest::VERSION).not_to be nil
  end

  describe ".on_response_captured" do
    before { described_class.restore_default_response_capture_behavior }

    context 'when it has not been set via a block' do
      it "it is nil" do
        expect(described_class.on_response_captured).to be_nil
      end
    end

    context 'when we set it via a block' do
      let(:block) do
        ->(identifier:, result:) { puts "identifier: #{identifier}, result: #{result}" }
      end
      before { described_class.on_response_captured(&block) }

      it "it is the block" do
        expect(described_class.on_response_captured).to eq(block)
      end
    end
  end

  describe "self.deprecator" do
    it "has a valid deprecator" do
      expect(described_class.deprecator).to be_instance_of(ActiveSupport::Deprecation)
      expect(described_class.deprecator.deprecation_horizon).to eq("3.0")
      expect(described_class.deprecator.gem_name).to eq("Alchemrest")
    end
  end
end
