# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Data::Graph do
  let(:top_level_data_class) do
    user = nested_data_class
    Class.new(Alchemrest::Data) do
      schema do |s|
        {
          required: {
            account_number: s.string,
            members: s.many_of(user),
          },
        }
      end
    end
  end

  let(:nested_data_class) do
    Class.new(Alchemrest::Data) do
      schema do |s|
        {
          required: {
            token: s.string,
            name: s.string,
            member_type: s.string,
            created_on: s.date,
          },
        }
      end

      configure_response_capture do
        safe :token
        omitted :created_on
      end
    end
  end

  subject { described_class.new(type:, sub_graphs:, fields:) }
  let(:type) { top_level_data_class }
  let(:sub_graphs) { { members: described_class.new(type: nested_data_class) } }
  let(:fields) { { account_number: Alchemrest::Data::Field.new(transform: Morpher::Transform::STRING, name: "string") } }

  describe "new" do
    it "builds" do
      expect { subject }.not_to raise_error
      expect(subject).to be_a(described_class)
    end

    context "when we use a type that's not a transform type" do
      let(:type) { Class.new }

      it "does raise" do
        expect {
          subject
        }.to raise_error(ArgumentError, "Graph types must be branching Alchemrest::Data class")
      end
    end

    context "when sub_graphs is present and not a hash" do
      let(:sub_graphs) { [] }

      it "does raise" do
        expect { subject }.to raise_error(ArgumentError, "sub_graphs must be a hash of graphs")
      end
    end

    context "when fields is present and not a hash" do
      let(:fields) { [] }

      it "does raise" do
        expect { subject }.to raise_error(ArgumentError, "fields must be a hash of fields")
      end
    end

    context "when we use a sub graph that is not themselves Graph" do
      let(:sub_graphs) { { members: nested_data_class } }

      it "does raise" do
        expect { subject }.to raise_error(ArgumentError, "sub_graphs must be a hash of graphs")
      end
    end

    context "when a field's value is not a Alchemrest::Data::Field" do
      let(:top_level_data_class) do
        user = nested_data_class
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                account_number: s.string,
                members: s.many_of(user),
                field_we_cannot_get_right: s.many_of(user),
              },
            }
          end
        end
      end
      let(:fields) do
        {
          account_number: Alchemrest::Data::Field.new(transform: Morpher::Transform::STRING, name: "string"),
          field_we_cannot_get_right: described_class.new(type: nested_data_class),
        }
      end

      it "does raise" do
        expect { subject }.to raise_error(ArgumentError, "fields must be a hash of fields")
      end
    end
  end

  describe "#type" do
    it "returns the right type" do
      expect(subject.type).to eq(top_level_data_class)
    end
  end

  describe "#sub_graphs" do
    it 'returns both branch and leaf fields' do
      expect(subject.sub_graphs).to eq sub_graphs
    end

    context "when no branch fields given" do
      let(:sub_graphs) { nil }

      it 'returns just the leaf fields' do
        expect(subject.sub_graphs).to be_nil
      end
    end
  end

  describe "#children" do
    it "returns sub_graphs" do
      expect(subject.children).to eq(subject.sub_graphs)
    end
  end

  describe "#fields" do
    it 'returns leaf fields' do
      expect(subject.fields).to eq fields
    end

    context "when no branch fields given" do
      let(:fields) { nil }

      it 'returns just the leaf fields' do
        expect(subject.fields).to be_nil
      end
    end
  end
end
