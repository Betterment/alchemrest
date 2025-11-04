# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Data::Schema, squad: :employee_wellness do
  describe "self.graph" do
    let(:top_level_data_class) do
      user = nested_data_class
      Class.new(Alchemrest::Data) do
        schema do |s|
          {
            required: {
              members: s.many_of(user),
              account_number: s.string,
            },
            optional: {
              routing_number: s.string,
              non_members: s.many_of(user),
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
      end
    end

    subject do
      top_level_data_class
    end

    it "returns a graph" do
      expect(subject.graph).to be_a(Alchemrest::Data::Graph)
      expect(subject.graph.type).to eq(top_level_data_class)
      expect(subject.graph.sub_graphs.keys).to eq(%i(members non_members))
      expect(subject.graph.sub_graphs[:members]).to be_a(Alchemrest::Data::Graph)
      expect(subject.graph.sub_graphs[:members].type).to eq(nested_data_class)
      expect(subject.graph.fields.select { |_k, v| v.required }.keys).to eq(%i(members account_number))
      expect(subject.graph.fields.reject { |_k, v| v.required }.keys).to eq(%i(routing_number non_members))
      expect(subject.graph.fields.values.map { |f| f.name }).to eq(%w(members account_number routing_number non_members))
    end

    context "with transform that doesn't support output type" do
      let(:top_level_data_class) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                account_number: Morpher::Transform::STRING,
              },
              optional: {
                routing_number: s.string,
              },
            }
          end
        end
      end

      it "returns a graph" do
        expect(subject.graph).to be_a(Alchemrest::Data::Graph)
      end
    end

    context "with no nested types" do
      let(:top_level_data_class) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                account_number: s.string,
              },
              optional: {
                routing_number: s.string,
              },
            }
          end
        end
      end

      it "returns a graph" do
        expect(subject.graph).to be_a(Alchemrest::Data::Graph)
        expect(subject.graph.type).to eq(top_level_data_class)
        expect(subject.graph.sub_graphs.empty?).to eq true
        expect(subject.graph.fields.keys).to eq(%i(account_number routing_number))
      end
    end

    context "with only nested types" do
      let(:top_level_data_class) do
        user = nested_data_class
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                members: s.many_of(user),
              },
              optional: {
                non_members: s.many_of(user),
              },
            }
          end
        end
      end

      it "returns a graph" do
        expect(subject.graph).to be_a(Alchemrest::Data::Graph)
        expect(subject.graph.type).to eq(top_level_data_class)
        expect(subject.graph.sub_graphs.keys).to eq(
          %i(members non_members),
        )
        expect(subject.graph.sub_graphs[:members]).to be_a(Alchemrest::Data::Graph)
        expect(subject.graph.sub_graphs[:members].type).to eq(nested_data_class)
        expect(subject.graph.fields.keys).to eq(%i(members non_members))
      end
    end
  end
end
