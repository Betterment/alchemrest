# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Request::Returns do
  subject { described_class.new(domain_type, path_to_payload, allow_empty_response) }

  let(:domain_type) do
    Class.new(Alchemrest::Data) do
      schema do |s|
        {
          required: {
            name: s.from.string,
            age: s.from.number,
            ssn: s.from.string,
            hash: s.from.string,
          },
        }
      end

      configure_response_capture do
        safe 'ssn'
        omitted 'hash'
      end
    end
  end

  let(:path_to_payload) { nil }
  let(:allow_empty_response) { false }

  describe "#sanitize_step" do
    context 'when path to payload is not defined' do
      it 'builds a sanitize step based on the domain type capture configuration' do
        expect(subject.sanitize_step).to be_a_instance_of(Alchemrest::Response::Pipeline::Sanitize)
        expect(subject.sanitize_step.safe).to eq([Alchemrest::HashPath.new(['ssn'])])
      end
    end

    context 'when path to payload is defined' do
      let(:path_to_payload) { ['data'] }

      it 'builds a sanitize step based on the domain type capture configuration' do
        expect(subject.sanitize_step).to be_a_instance_of(Alchemrest::Response::Pipeline::Sanitize)
        expect(subject.sanitize_step.safe).to eq([Alchemrest::HashPath.new(%w(data ssn))])
      end
    end
  end

  describe "#omit_step" do
    context 'when path to payload is not defined' do
      it "builds an omit step based on the domain type capture configuration" do
        expect(subject.omit_step).to be_an_instance_of(Alchemrest::Response::Pipeline::Omit)
        expect(subject.omit_step.omit).to eq([Alchemrest::HashPath.new(['hash'])])
      end
    end

    context 'when path to payload is defined' do
      let(:path_to_payload) { ['data'] }

      it "builds an omit step based on the domain type capture configuration" do
        expect(subject.omit_step).to be_an_instance_of(Alchemrest::Response::Pipeline::Omit)
        expect(subject.omit_step.omit).to eq([Alchemrest::HashPath.new(%w(data hash))])
      end
    end
  end

  describe "#included" do
    let(:host) do
      Class.new(Alchemrest::Request) do
        endpoint :get, '/v1/user'
      end
    end

    context 'when path to payload is not defined' do
      it 'modifies the pipelines correctly' do
        subject.included(host)

        instance = host.new

        expect(instance.response_transformer.steps[1]).to eq(Alchemrest::Response::Pipeline::ExtractPayload.new)
        expect(instance.response_transformer.steps[2]).to eq(domain_type::TRANSFORM)

        expect(instance.capture_transformer.steps[1]).to eq(subject.sanitize_step)
        expect(instance.capture_transformer.steps[2]).to eq(subject.omit_step)
      end
    end

    context 'when path to payload is defined' do
      let(:path_to_payload) { ['data'] }

      it 'modifies the pipelines correctly' do
        subject.included(host)

        instance = host.new

        expect(instance.response_transformer.steps[1]).to eq(Alchemrest::Response::Pipeline::ExtractPayload.new(path_to_payload))
        expect(instance.response_transformer.steps[2]).to eq(domain_type::TRANSFORM)

        expect(instance.capture_transformer.steps[1]).to eq(subject.sanitize_step)
        expect(instance.capture_transformer.steps[2]).to eq(subject.omit_step)
      end
    end

    context 'when allows empty response is false' do
      it 'modifies the pipelines correctly' do
        subject.included(host)

        instance = host.new

        expect(instance.response_transformer.steps[1]).to eq(Alchemrest::Response::Pipeline::ExtractPayload.new(path_to_payload))
        expect(instance.response_transformer.steps[2]).to eq(domain_type::TRANSFORM)

        expect(instance.capture_transformer.steps[1]).to eq(subject.sanitize_step)
        expect(instance.capture_transformer.steps[2]).to eq(subject.omit_step)
      end
    end

    context 'when allows empty response is true' do
      let(:allow_empty_response) { true }

      it 'modifies the pipelines correctly' do
        subject.included(host)

        instance = host.new

        expect(instance.response_transformer.steps[1]).to eq(Alchemrest::Response::Pipeline::ExtractPayload.new(path_to_payload, true))
        expect(instance.response_transformer.steps[2]).to eq(domain_type::TRANSFORM)

        expect(instance.capture_transformer.steps[1]).to eq(subject.sanitize_step)
        expect(instance.capture_transformer.steps[2]).to eq(subject.omit_step)
      end
    end
  end
end
