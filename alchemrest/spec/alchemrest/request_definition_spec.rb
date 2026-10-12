# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::RequestDefinition do
  let(:request_implementation) do
    Class.new(Alchemrest::Request) do
      def initialize(id:)
        @id = id
        super()
      end

      def path
        "/api/v1/users/#{@id}"
      end

      def http_method
        'get'
      end
    end
  end

  describe "#name" do
    subject { described_class.new(:get_user, request_implementation) }

    it "returns the name of the request" do
      expect(subject.name).to eq(:get_user)
    end
  end

  describe "#request_class" do
    subject { described_class.new(:get_user, request_implementation) }

    it "returns the request class" do
      expect(subject.request_class).to eq(request_implementation)
    end
  end

  describe "#builder_block" do
    let(:builder_block) { proc { |request| request.defaults = { id: 1 } } }

    subject { described_class.new(:get_user, request_implementation, &builder_block) }

    it "returns the block passed to the definition" do
      expect(subject.builder_block).to eq(builder_block)
    end
  end

  describe "#build_request" do
    subject { described_class.new(:get_user, request_implementation) }

    it "returns an request object" do
      expect(subject.build_request(nil, { id: 1 })).to be_a(request_implementation)
    end

    context "with a block that takes a `RequestDefintion::Builder`" do
      subject do
        described_class.new(:get_user, request_implementation) { |request| request.defaults = { id: } }
      end

      it "returns an request object" do
        context = Struct.new(:id).new(1)
        expect(subject.build_request(context)).to be_a(request_implementation)
      end
    end
  end
end
