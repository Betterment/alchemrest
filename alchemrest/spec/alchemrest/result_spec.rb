# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Result do
  describe "self.Ok" do
    it 'returns an instance of described_class::Ok' do
      expect(described_class.Ok(42)).to be_a(described_class::Ok)
    end

    it 'allows nil values' do
      expect(described_class.Ok(nil)).to be_a(described_class::Ok)
    end

    it 'is equal to another Ok result with the same value' do
      expect(described_class.Ok(:value)).to eq(described_class.Ok(:value))
    end

    it 'is not equal to another Ok result with a different value' do
      expect(described_class.Ok(:value)).not_to eq(described_class.Ok(:different_value))
    end
  end

  describe 'self.Error' do
    it 'returns an instance of described_class::Error for a string' do
      expect(described_class.Error("Something broke")).to be_a(described_class::Error)
    end

    it 'returns an instance of described_class::Error for an exception' do
      expect(described_class.Error(Alchemrest::Error.new)).to be_a(described_class::Error)
    end

    it 'disallows nil values' do
      expect { described_class.Error(nil) }
        .to raise_error(ArgumentError, "Error must be a string or one of the types defined in Alchemrest.rescuable_exceptions")
    end

    it 'disallows values that are not part of rescuable exceptions or a string' do
      expect { described_class.Error(1) }
        .to raise_error(ArgumentError, "Error must be a string or one of the types defined in Alchemrest.rescuable_exceptions")
    end

    it 'is equal to another Error result with the same string value' do
      expect(described_class.Error("Something broke")).to eq(described_class.Error("Something broke"))
    end

    it 'is equal to another Error result with the same exception value' do
      e = Alchemrest::Error.new
      expect(described_class.Error(e)).to eq(described_class.Error(e))
    end

    it 'is not equal to another Error result with a different value' do
      expect(described_class.Error("Something broke")).not_to eq(described_class.Error("its on fire!"))
    end
  end

  describe 'self.[]' do
    it 'returns the class' do
      expect(described_class[]).to eq(described_class)
    end
  end

  describe '#transform' do
    context 'when Ok' do
      it 'maps the underlying value if Ok' do
        expect(described_class.Ok(42).transform(&:digits)).to eq(described_class.Ok([2, 4]))
      end

      it 'raises an error if no block given' do
        expect { described_class.Ok(42).transform }.to raise_error(ArgumentError, 'no block given')
      end
    end

    context 'when Error' do
      subject { described_class.Error("Something broke") }

      it 'returns itself' do
        expect(subject.transform(&:digits)).to equal(subject)
      end

      it 'raises an error if no block given' do
        expect { subject.transform }.to raise_error(ArgumentError, 'no block given')
      end
    end
  end

  describe '#unwrap_or_rescue' do
    context 'when Ok' do
      it 'returns the value' do
        expect(described_class.Ok(42).unwrap_or_rescue { 10 }).to eq(42)
      end

      it 'raises if no block is given' do
        expect { described_class.Ok(42).unwrap_or_rescue }.to raise_error(ArgumentError, 'no error handler given')
      end
    end

    context 'when Error' do
      before do
        allow(Alchemrest).to receive(:handle_rescued_result)
      end

      it 'returns the block value and calls our handler' do
        expect(described_class.Error("Something broke").unwrap_or_rescue { 42 }).to eq(42)
        expect(Alchemrest).to have_received(:handle_rescued_result)
      end

      it 'raises if no error handler is given' do
        expect { described_class::Error("Something broke").unwrap_or_rescue }
          .to raise_error(ArgumentError, 'no error handler given')
      end
    end
  end

  describe '#unwrap_or_raise!' do
    it 'returns the value when Ok' do
      expect(described_class.Ok(42).unwrap_or_raise!).to eq(42)
    end

    it 'raises if a string error' do
      expect { described_class::Error("Something broke").unwrap_or_raise! }
        .to raise_error("Something broke")
    end

    it 'raises if an exception error' do
      expect { described_class::Error(Alchemrest::Error.new).unwrap_or_raise! }
        .to raise_error(Alchemrest::Error)
    end
  end

  describe "#deconstruct" do
    context "for an Ok result" do
      subject { described_class.Ok(42) }

      it 'returns an array with the raw value' do
        expect(subject.deconstruct).to eq([42])
      end
    end

    context "for an Error result" do
      subject { described_class.Error("Something broke") }

      it 'returns an array with the error' do
        expect(subject.deconstruct).to eq([Alchemrest::Error.new("Something broke")])
      end
    end
  end

  describe "#deconstruct_keys" do
    context "for an Ok result" do
      subject { described_class.Ok(42) }

      it 'returns an array with the raw value' do
        expect(subject.deconstruct_keys(nil)).to eq({ value: 42 })
      end
    end

    context "for an Error result" do
      subject { described_class.Error("Something broke") }

      it 'returns a hash with the error' do
        expect(subject.deconstruct_keys(nil)).to eq({ error: Alchemrest::Error.new("Something broke") })
      end
    end
  end

  describe "case .. in pattern matching" do
    context "for an Ok result" do
      subject { described_class.Ok(42) }

      it 'lets us extract the value' do
        value = case subject
                  in Alchemrest::Result::Ok(v)
                    v
                  in Alchemrest::Result::Error
                    'incorrect'
                end
        expect(value).to eq(42)
      end
    end

    context "for an Error result" do
      subject { described_class.Error("Something broke") }

      it 'matches on the exact error string' do
        value = case subject
                  in Alchemrest::Result::Ok
                    'incorrect'
                  in Alchemrest::Result::Error({error: 'Something broke'})
                    'correct'
                end

        expect(value).to eq('correct')
      end
    end

    context "for an Error result with a nested response object" do
      let(:raw_response) do
        instance_double(
          Faraday::Response,
          status: 503,
          success?: false,
          body: nil,
        )
      end
      let(:response_error) { Alchemrest::ServerError.new(Alchemrest::Response.new(raw_response)) }

      subject { described_class.Error(response_error) }

      it 'matches on the status of the nested ServerError object' do
        value = case subject
                  in Alchemrest::Result::Ok
                    'incorrect'
                  in Alchemrest::Result::Error({status: 503})
                    'correct'
                end

        expect(value).to eq('correct')
      end
    end
  end

  describe "self.for" do
    context "with a block with a single Ok result we try to unwrap" do
      let(:ok_result) { described_class.Ok(42) }

      subject do
        described_class.for { |try| try.unwrap ok_result }
      end

      it "returns the ok_result" do
        expect(subject).to eq(described_class.Ok(42))
      end
    end

    context "with a block with a single Ok result we don't try to unwrap" do
      let(:ok_result) { described_class.Ok(42) }

      subject do
        described_class.for { |_try| ok_result }
      end

      it "returns the ok_result" do
        expect(subject).to eq(described_class.Ok(42))
      end
    end

    context "with a block with a single error result we try to unwrap" do
      let(:error_result) { described_class.Error('Something broke') }
      subject do
        described_class.for { |try| try.unwrap error_result }
      end

      it "returns the error_result" do
        expect(subject).to eq(described_class.Error('Something broke'))
      end
    end

    context "with a block with a single error result we don't try to unwrap" do
      let(:error_result) { described_class.Error('Something broke') }
      subject do
        described_class.for { |_try| error_result }
      end

      it "returns the error_result" do
        expect(subject).to eq(described_class.Error('Something broke'))
      end
    end

    context "with a block with an error result in the middle that we try to unwrap" do
      let(:error_result) { described_class.Error('Something broke') }
      let(:ok_result) { described_class.Ok(42) }
      let(:side_effect_tracker) { {} }

      subject do
        described_class.for do |try|
          try.unwrap ok_result
          try.unwrap error_result
          side_effect_tracker[:value] = true
        end
      end

      it "returns an error and short circuits execution" do
        expect(subject).to eq(described_class.Error('Something broke'))
        expect(side_effect_tracker[:value]).to eq(nil)
      end
    end
  end
end
