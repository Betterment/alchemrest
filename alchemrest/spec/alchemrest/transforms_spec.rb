# frozen_string_literal: true

require 'spec_helper'

class TransformTester < Alchemrest::Data
end

class Sample < TransformTester
  schema do |s|
    {
      required: {
        name: s.string,
      },
    }
  end
end

class FullNameSample < TransformTester
  schema do |s|
    {
      required: {
        first_name: s.string,
        last_name: s.string,
        type: s.string,
      },
    }
  end
end

class SimpleNameSample < TransformTester
  schema do |s|
    {
      required: {
        name: s.string,
        type: s.string,
      },
    }
  end
end

RSpec.describe Alchemrest::Transforms do
  describe '.from' do
    it "returns the FromChain module" do
      expect(described_class.from).to eq(Alchemrest::Transforms::FromChain)
    end
  end

  describe 'self.enum' do
    it "has an output type" do
      expect(described_class.enum(%i(foo bar)).output_type).to eq described_class::OutputType.simple(T.any(Symbol, String))
    end

    context 'with hashes' do
      context 'with enum values' do
        let(:enum_test_class) do
          Class.new(TransformTester) do
            schema do |s|
              {
                required: {
                  operating_system: s.enum({ 4 => 'MAC', 3 => 'WINDOWS', 2 => 'LINUX', 1 => 'OTHER' }),
                },
              }
            end
          end
        end

        subject { enum_test_class }

        it 'returns valid when value found' do
          result = subject::TRANSFORM.call({ 'operating_system' => 2 })
          expect(result.from_right).to eq(enum_test_class.new(operating_system: 'LINUX'))
        end

        it 'returns error when value not found' do
          result = subject::TRANSFORM.call({ 'operating_system' => 42 })
          expect(result.from_left).to be_a(Morpher::Transform::Error)
        end
      end
    end

    context 'with arrays' do
      context 'with stringy enum values' do
        let(:enum_test_class) do
          Class.new(TransformTester) do
            schema do |s|
              {
                required: {
                  operating_system: s.enum(%w(mac windows linux other).freeze),
                },
              }
            end
          end
        end

        subject { enum_test_class }

        it 'returns valid when value found' do
          result = subject::TRANSFORM.call({ 'operating_system' => 'other' })
          expect(result.from_right).to eq(enum_test_class.new(operating_system: 'other'))
        end

        it 'returns error when value not found' do
          result = subject::TRANSFORM.call({ 'operating_system' => 42 })
          expect(result.from_left).to be_a(Morpher::Transform::Error)
        end
      end

      context 'with symbol enum values' do
        let(:enum_test_class) do
          Class.new(TransformTester) do
            schema do |s|
              {
                required: {
                  key: s.enum(%i(key_one key_two key_three)),
                },
              }
            end
          end
        end

        subject { enum_test_class }

        it 'returns valid when value found' do
          result = subject::TRANSFORM.call({ 'key' => 'key_one' })
          expect(result.from_right).to eq(enum_test_class.new(key: :key_one))
        end

        it 'returns error when value not found' do
          result = subject::TRANSFORM.call({ 'key' => 'key_four' })
          expect(result.from_left).to be_a(Morpher::Transform::Error)
        end
      end

      context 'with mixed enum values' do
        let(:enum_test_class) do
          Class.new(TransformTester) do
            schema do |s|
              {
                required: {
                  key: s.enum([:key_one, 2, 'key_three']),
                },
              }
            end
          end
        end

        subject { enum_test_class }

        it 'returns valid symbol when found' do
          result = subject::TRANSFORM.call({ 'key' => 'key_one' })
          expect(result.from_right).to eq(enum_test_class.new(key: :key_one))
        end

        it 'returns valid number when found' do
          result = subject::TRANSFORM.call({ 'key' => 2 })
          expect(result.from_right).to eq(enum_test_class.new(key: 2))
        end

        it 'returns valid string when found' do
          result = subject::TRANSFORM.call({ 'key' => 'key_three' })
          expect(result.from_right).to eq(enum_test_class.new(key: 'key_three'))
        end

        it 'returns error when value not found' do
          result = subject::TRANSFORM.call({ 'key' => 'key_four' })
          expect(result.from_left).to be_a(Morpher::Transform::Error)
        end
      end
    end
  end

  describe 'self.one_of' do
    let(:one_of_test_class) do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              one_thing: s.one_of(Sample),
            },
          }
        end
      end
    end
    subject { one_of_test_class }

    it 'returns valid when value found' do
      result = subject::TRANSFORM.call({ 'one_thing' => { 'name' => 'Betterbot' } })
      expect(result.from_right).to eq(one_of_test_class.new(one_thing: Sample.new(name: 'Betterbot')))
    end

    it 'returns error when value not found' do
      result = subject::TRANSFORM.call({})
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end

    context "with polymorphism" do
      let(:one_of_test_class) do
        Class.new(TransformTester) do
          schema do |s|
            {
              required: {
                one_thing: s.one_of(simple_name: SimpleNameSample, full_name: FullNameSample, discriminator: 'type'),
              },
              allow_additional_properties: true,
            }
          end
        end
      end

      it 'returns valid when value found' do
        result = subject::TRANSFORM.call({ 'one_thing' => { 'type' => 'simple_name', 'name' => 'Betterbot' } })
        expect(result.from_right).to eq(one_of_test_class.new(one_thing: SimpleNameSample.new(type: 'simple_name', name: 'Betterbot')))

        result = subject::TRANSFORM.call({ 'one_thing' => { 'type' => 'full_name', 'first_name' => 'Better', 'last_name' => 'Bot' } })
        expect(result.from_right)
          .to eq(one_of_test_class.new(one_thing: FullNameSample.new(type: 'full_name', first_name: 'Better', last_name: 'Bot')))
      end

      it 'raise error on unknown types' do
        result = subject::TRANSFORM.call({ 'one_thing' => { 'type' => nil, 'name' => 'Betterbot' } })
        expect(result.from_left.compact_message).to include(
          "Expected discriminator type to produce a value which is one of simple_name,full_name but got nil",
        )
      end
    end
  end

  describe 'self.many_of' do
    let(:many_of_test_class) do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              many_of_things: s.many_of(Sample),
            },
          }
        end
      end
    end

    subject { many_of_test_class }

    it 'returns valid when value found' do
      result = subject::TRANSFORM.call({ 'many_of_things' => [{ 'name' => 'Betterbot' }, { 'name' => 'Better Betterbot' }] })
      expect(result.from_right).to eq(many_of_test_class.new(many_of_things: [Sample.new(name: 'Betterbot'),
                                                                              Sample.new(name: 'Better Betterbot')]))
    end

    it 'returns error when value not found' do
      result = subject::TRANSFORM.call({})
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end
  end

  describe 'using allow_additional_properties' do
    subject { allow_additional_properties_of_test_class }

    context 'when default' do
      let(:allow_additional_properties_of_test_class) do
        Class.new(TransformTester) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
              optional: {
                optional_property: s.string,
              },
            }
          end
        end
      end

      it 'returns valid when additional field found' do
        result = allow_additional_properties_of_test_class::TRANSFORM.call({ 'name' => 'Betterbot', 'additional_property' => 'value' })
        expect(result.from_right).to eq(allow_additional_properties_of_test_class.new(name: 'Betterbot', optional_property: nil))
      end
    end

    context 'when true' do
      let(:allow_additional_properties_of_test_class) do
        Class.new(TransformTester) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
              optional: {
                optional_property: s.string,
              },
              allow_additional_properties: true,
            }
          end
        end
      end

      it 'returns valid when additional field found' do
        result = allow_additional_properties_of_test_class::TRANSFORM.call({ 'name' => 'Betterbot', 'additional_property' => 'value' })
        expect(result.from_right).to eq(allow_additional_properties_of_test_class.new(name: 'Betterbot', optional_property: nil))
      end

      it 'only transforms required and optional properties' do
        result = allow_additional_properties_of_test_class::TRANSFORM.call({
                                                                             'name' => 'Betterbot',
                                                                             'optional_property' => 'optional_value',
                                                                             'additional_property' => 'value',
                                                                           })
        expect(result.from_right.name).to eq('Betterbot')
        expect(result.from_right.optional_property).to eq('optional_value')
        expect(result.from_right.respond_to?(:additional_property)).to eq(false)
      end

      context 'when there are missing keys' do
        it 'only shows the missing fields in the error message' do
          result = allow_additional_properties_of_test_class::TRANSFORM.call({ 'additional_property' => 'value' })
          expect(result.from_left.compact_message).to include("Missing keys: [:name], Unexpected keys: []")
        end
      end
    end

    context 'when false' do
      let(:allow_additional_properties_of_test_class) do
        Class.new(TransformTester) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
              allow_additional_properties: false,
            }
          end
        end
      end

      it 'returns error when additional field found' do
        result = subject::TRANSFORM.call({ 'name' => 'Betterbot', 'additional_property' => 'value' })
        expect(result.from_left).to be_a(Morpher::Transform::Error)
        expect(result.from_left.compact_message).to include("Missing keys: [], Unexpected keys: [:additional_property]")
      end
    end
  end

  describe 'self.boolean' do
    subject do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              active: s.boolean,
            },
          }
        end
      end
    end

    it "has an output type" do
      expect(described_class.boolean.output_type).to eq described_class::OutputType.simple(T::Boolean)
    end

    it 'returns the boolean' do
      result = subject::TRANSFORM.call({ 'active' => true })
      expect(result.from_right.active).to eq(true)
    end

    it 'returns error when value is not a boolean' do
      result = subject::TRANSFORM.call({ 'active' => "true" })
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end
  end

  describe 'self.date' do
    subject { date_test_class }
    let(:date_test_class) do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              start_on: s.date,
            },
          }
        end
      end
    end

    it "has an output type" do
      expect(described_class.date.output_type).to eq described_class::OutputType.simple(Date)
    end

    it 'returns the correct date type' do
      result = subject::TRANSFORM.call({ 'start_on' => '2022-01-01' })
      expect(result.from_right.start_on).to eq(Date.new(2022, 1, 1)).and be_a(Date)
    end

    it 'returns error when value not found' do
      result = subject::TRANSFORM.call({})
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end

    it 'returns error when date format is not Date.iso8601 format' do
      result = subject::TRANSFORM.call({ 'start_on' => '2022/12/01' })
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end
  end

  describe 'self.integer' do
    subject do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              percentage_complete: s.integer,
            },
          }
        end
      end
    end

    it "has an output type" do
      expect(described_class.integer.output_type).to eq described_class::OutputType.simple(Integer)
    end

    it 'returns the correct numeric type' do
      result = subject::TRANSFORM.call({ 'percentage_complete' => 1 })
      expect(result.from_right.percentage_complete).to eq(1).and be_a(Integer)
    end

    it 'returns error when value not found' do
      result = subject::TRANSFORM.call({})
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end
  end

  describe 'self.string' do
    subject do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              name: s.string,
            },
          }
        end
      end
    end

    it "has an output type" do
      expect(described_class.string.output_type).to eq described_class::OutputType.simple(String)
    end

    it 'returns the correct numeric type' do
      result = subject::TRANSFORM.call({ 'name' => 'Test' })
      expect(result.from_right.name).to eq('Test')
    end

    it 'returns error when value not found' do
      result = subject::TRANSFORM.call({})
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end
  end

  describe 'self.float' do
    subject do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              percentage_complete: s.float,
            },
          }
        end
      end
    end

    it "has an output type" do
      expect(described_class.float.output_type).to eq described_class::OutputType.simple(Float)
    end

    it 'returns the correct type' do
      result = subject::TRANSFORM.call({ 'percentage_complete' => 1.2 })
      expect(result.from_right.percentage_complete).to eq(1.2).and be_a(Float)
    end

    it 'returns error when value not found' do
      result = subject::TRANSFORM.call({})
      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end
  end

  describe 'self.money' do
    it "has an output type" do
      expect(described_class.money(:dollars).output_type).to eq described_class::OutputType.simple(Money)
    end

    context "when :dollars" do
      subject do
        Class.new(TransformTester) do
          schema do |s|
            {
              required: {
                amount: s.money(:dollars),
              },
            }
          end
        end
      end

      it 'returns the correct type' do
        result = subject::TRANSFORM.call({ 'amount' => 10 })
        expect(result.from_right.amount).to eq(Money.from_dollars(10)).and be_a(Money)
      end

      it 'returns error when value not found' do
        result = subject::TRANSFORM.call({})
        expect(result.from_left).to be_a(Morpher::Transform::Error)
      end
    end

    context "when :cents" do
      subject do
        Class.new(TransformTester) do
          schema do |s|
            {
              required: {
                amount: s.money(:cents),
              },
            }
          end
        end
      end

      it 'returns the correct type' do
        result = subject::TRANSFORM.call({ 'amount' => 10_00 })
        expect(result.from_right.amount).to eq(Money.from_dollars(10)).and be_a(Money)
      end

      it 'returns error when value not found' do
        result = subject::TRANSFORM.call({})
        expect(result.from_left).to be_a(Morpher::Transform::Error)
      end
    end
  end

  describe 'self.number' do
    subject do
      Class.new(TransformTester) do
        schema do |s|
          {
            required: {
              percentage_complete: s.number,
            },
          }
        end
      end
    end

    it "builds a transform witht he right output type" do
      expect(described_class.number.output_type).to eq described_class::OutputType.simple(T.any(Float, Integer))
    end

    context "when integer" do
      it 'returns the correct numeric type' do
        result = subject::TRANSFORM.call({ 'percentage_complete' => 1 })
        expect(result.from_right.percentage_complete).to eq(1).and be_a(Numeric)
      end

      it 'returns error when value not found' do
        result = subject::TRANSFORM.call({})
        expect(result.from_left).to be_a(Morpher::Transform::Error)
      end
    end

    context "when float" do
      it 'returns the correct numeric type' do
        result = subject::TRANSFORM.call({ 'percentage_complete' => 1.2 })
        expect(result.from_right.percentage_complete).to eq(1.2).and be_a(Numeric)
      end
    end
  end
end
