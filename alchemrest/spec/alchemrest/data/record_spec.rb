# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Data::Record do
  subject do
    Class.new(Alchemrest::Data) do
      schema do |s|
        {
          required: {
            name: s.string,
            age: s.integer,
          },

        }
      end
    end
  end

  describe "#included" do
    it "includes Adamantium::Flat" do
      expect(subject.ancestors).to include(Adamantium::Flat)
    end

    it "sets a TRANSFORM which returns a valid user object and is typed" do
      expect(subject::TRANSFORM.output_type).to eq(Alchemrest::Transforms::OutputType.simple(subject))
      result = subject::TRANSFORM.call({ 'name' => 'Betterbot', 'age' => 20 })

      expect(result.from_right).to eq(subject.new(name: 'Betterbot', age: 20))
    end

    it "sets a TRANSFORM which returns an error for bad transform values" do
      result = subject::TRANSFORM.call({ 'name' => 'Betterbot' })

      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end

    it "sets a TRANSORM which returns an error for non hash transform values" do
      result = subject::TRANSFORM.call("Test")

      expect(result.from_left).to be_a(Morpher::Transform::Error)
    end

    context "when we have a schema where allow additional properties is false" do
      subject do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
                age: s.integer,
              },
              allow_additional_properties: false,
            }
          end
        end
      end

      context "and we provide extra values" do
        it "it sets a TRANSFORM that returns an error user for bad transform values" do
          result = subject::TRANSFORM.call({ 'name' => 'Betterbot', 'age' => 20, 'extra' => 'value' })

          expect(result.from_left).to be_a(Morpher::Transform::Error)
        end
      end

      context "and we don't provide extra values" do
        it "it sets a TRANSFORM that returns a valid object" do
          expect(subject::TRANSFORM.output_type).to eq(Alchemrest::Transforms::OutputType.simple(subject))
          result = subject::TRANSFORM.call({ 'name' => 'Betterbot', 'age' => 20 })

          expect(result.from_right).to eq(subject.new(name: 'Betterbot', age: 20))
        end
      end
    end

    context "when we have a schema where allow additional properties is true" do
      subject do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
                age: s.integer,
              },
              allow_additional_properties: true,
            }
          end
        end
      end

      context "and we provide extra values" do
        it "it sets a TRANSFORM that returns an error user for bad transform values" do
          result = subject::TRANSFORM.call({ 'name' => 'Betterbot', 'age' => 20, 'extra' => 'value' })

          expect(result.from_right).to eq(subject.new(name: 'Betterbot', age: 20))
        end
      end

      context "and we don't provide extra values" do
        it "sets a TRANSFORM that returns a valid object" do
          expect(subject::TRANSFORM.output_type).to eq(Alchemrest::Transforms::OutputType.simple(subject))
          result = subject::TRANSFORM.call({ 'name' => 'Betterbot', 'age' => 20 })

          expect(result.from_right).to eq(subject.new(name: 'Betterbot', age: 20))
        end
      end
    end

    context "when we have a schema with optional values" do
      subject do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
              },
              optional: {
                age: s.integer,
              },
            }
          end
        end
      end

      context "and we provide the optional values" do
        it "sets a TRANSFORM that returns a valid user object and is typed" do
          result = subject::TRANSFORM.call({ 'name' => 'Betterbot', 'age' => 20 })

          expect(result.from_right).to eq(subject.new(name: 'Betterbot', age: 20))
        end
      end

      context "and we don't provide the optional values" do
        it "sets a TRANSFORM that returns a valid user object" do
          result = subject::TRANSFORM.call({ 'name' => 'Betterbot' })

          expect(result.from_right).to eq(subject.new(name: 'Betterbot', age: nil))
        end
      end
    end
  end
end
