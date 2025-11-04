# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Data::CaptureConfiguration do
  let(:top_level_data_class) do
    user = nested_data_class
    Class.new(Alchemrest::Data) do
      schema do |s|
        {
          required: {
            account_number: s.string,
            group_secret: s.string,
            boring_identifier: s.string,
            group_name: s.string,
            created_on: s.date,
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

  let(:path_to_payload) { nil }

  subject do
    described_class.new(host_class: top_level_data_class, path_to_payload:) do
      safe :account_number, :group_secret
      omitted :boring_identifier
    end
  end

  describe "#safe_paths" do
    it "returns the safe paths for the full tree" do
      expect(subject.safe_paths).to eq([:account_number, :group_secret, { members: [:token] }])
    end

    context "when path_to_payload is specified" do
      let(:path_to_payload) { %i(data accounts) }

      it "returns the safe paths for the full tree with the prefix" do
        expect(subject.safe_paths)
          .to eq([
            { data: { accounts: :account_number } },
            { data: { accounts: :group_secret } },
            { data: { accounts: { members: [:token] } } },
          ])
      end
    end
  end

  describe "#omitted_paths" do
    it "returns the omitted paths for the full tree" do
      expect(subject.omitted_paths).to eq([:boring_identifier, { members: [:created_on] }])
    end

    context "when path_to_payload is specified" do
      let(:path_to_payload) { %i(data accounts) }

      it "returns the safe paths for the full tree with the prefix" do
        expect(subject.omitted_paths)
          .to eq([
            { data: { accounts: :boring_identifier } },
            { data: { accounts: { members: [:created_on] } } },
          ])
      end
    end
  end

  describe "#with_path_to_payload" do
    it "returns a new instance with the path_to_payload set and other attributes the same" do
      new_instance = subject.with_path_to_payload(%i(data accounts))
      expect(new_instance.path_to_payload).to eq(%i(data accounts))
      expect(new_instance.safe_keys).to eq(subject.safe_keys)
      expect(new_instance.omitted_keys).to eq(subject.omitted_keys)
    end
  end
end
