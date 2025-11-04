# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::FactoryBot do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    FactoryBot.define do
      alchemrest_factory :dummy_factory, class: 'DataClass' do
        id { 1 }
        name { "test" }
        child { association(:nested_dummy_factory) }
        not_required { Alchemrest::FactoryBot::OmitKey.instance }
      end

      alchemrest_factory :nested_dummy_factory, class: 'NestedDataClass' do
        id { 1 }
        description { "nested test" }
        child { association(:double_nested_dummy_factory) }
      end

      alchemrest_factory :double_nested_dummy_factory, class: 'DoubleNestedDataClass' do
        id { 1 }
        description { "double nested test" }
      end
    end
  end

  before do
    stub_const(
      "DoubleNestedDataClass",
      Class.new(Alchemrest::Data) do
        schema do |s|
          {
            required: {
              id: s.integer,
              description: s.string,
            },
          }
        end
      end,
    )

    stub_const(
      "NestedDataClass",
      Class.new(Alchemrest::Data) do
        schema do |s|
          {
            required: {
              id: s.integer,
              description: s.string,
              child: s.one_of(DoubleNestedDataClass),
            },
          }
        end
      end,
    )

    stub_const(
      "DataClass",
      Class.new(Alchemrest::Data) do
        schema do |s|
          {
            required: {
              id: s.integer,
              name: s.string,
              child: s.one_of(NestedDataClass),
            },
            optional: {
              not_required: s.string,
            },
          }
        end
      end,
    )
  end

  describe "when we create an alchemrest data object from a factory" do
    it "builds the object graph successfully" do
      object = FactoryBot.alchemrest_record_for(:dummy_factory)
      expect(object).to be_a(DataClass)
      expect(object.child).to be_a(NestedDataClass)
      expect(object.child.child).to be_a(DoubleNestedDataClass)
    end
  end

  describe "when we create an alchemrest hash from a factory" do
    it "creates a fully nested hash with all the data we need" do
      data = FactoryBot.alchemrest_hash_for(:dummy_factory)

      expect(data).to eq({
                           id: 1,
                           name: "test",
                           child: {
                             id: 1,
                             description: "nested test",
                             child: {
                               id: 1,
                               description: "double nested test",
                             },
                           },
                         })
    end
  end
end
