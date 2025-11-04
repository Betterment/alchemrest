# frozen_string_literal: true

require 'spec_helper'

class User < Alchemrest::Data
  schema do |s|
    {
      required: {
        name: s.string,
        age: s.integer,
      },
    }
  end

  configure_response_capture do
    safe :name
  end
end

class Group < Alchemrest::Data
  schema do |s|
    {
      required: {
        name: s.string,
        users: s.many_of(User),
      },
    }
  end
end

class InvalidUser < Alchemrest::Data
end

RSpec.describe Alchemrest::Data do
  subject do
    User
  end

  describe 'self.schema' do
    it "includes a new schema module in ancestors" do
      schema_module = subject.ancestors.find { |a| a.instance_of?(Alchemrest::Data::Schema) }
      expect(schema_module).not_to be_nil
    end
  end

  describe 'self.from_hash' do
    it "returns a valid user object from hash" do
      result = subject.from_hash({ 'name' => 'Betterbot', 'age' => 20 })
      expect(result).to eq(User.new(name: 'Betterbot', age: 20))
    end

    context 'when keys are not string' do
      it "returns a valid user object from hash" do
        result = subject.from_hash({ name: 'Betterbot', age: 20 })
        expect(result).to eq(User.new(name: 'Betterbot', age: 20))
      end
    end

    it "raises an error if we have a bad structure" do
      expected_error_message = 'Response does not match expected schema - ' \
                               'Morpher::Transform::Sequence/2/Alchemrest::Transforms::LooseHash: Missing keys: [:age], Unexpected keys: []'

      expect { subject.from_hash({ 'name' => 'Betterbot' }) }.to raise_error(Alchemrest::MorpherTransformError, expected_error_message)
    end
  end

  describe "self[]" do
    it "returns a sub class with an array transformation assigned to ::TRANSFORM and the same capture configuration" do
      expect(subject[]::TRANSFORM).to eq(subject::TRANSFORM.array)
      expect(subject[].capture_configuration).to eq(subject.capture_configuration)
    end
  end

  describe "self.configure_response_capture" do
    it "set the capture configuration" do
      test_class = Class.new(Alchemrest::Data) do
        schema do |s|
          {
            required: {
              foo: s.string,
              bar: s.string,
              baz: s.string,
            },
          }
        end

        configure_response_capture do
          safe :foo, :bar
          omitted :baz
        end
      end

      expect(test_class.capture_configuration).to be_a(Alchemrest::Data::CaptureConfiguration)
      expect(test_class.capture_configuration.safe_keys).to eq(%i(foo bar))
      expect(test_class.capture_configuration.omitted_keys).to eq([:baz])
    end
  end
end
