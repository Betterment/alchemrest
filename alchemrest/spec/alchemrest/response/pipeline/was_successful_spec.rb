# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Response::Pipeline::WasSuccessful do
  subject { described_class.new }
  let(:env) do
    Faraday::Env.new.tap do |e|
      e.method = :get
      e.url = URI("https://example.com")
    end
  end

  describe "#call" do
    let(:response) do
      Alchemrest::Response.new(
        instance_double(Faraday::Response, success?: success, status:, env: status),
      )
    end

    context "when the response is successful" do
      let(:success) { true }
      let(:status) { 200 }

      it "succeeds and returns the response as an Either" do
        expect(subject.call(response).from_right).to be_a(Alchemrest::Response)
      end
    end

    context "when the response is not successful" do
      let(:success) { false }
      let(:status) { 500 }

      it "fails and returns an error result" do
        expect(subject.call(response).from_left).to be_a(Alchemrest::ServerError)
      end
    end
  end

  describe "#==" do
    context 'with another instance' do
      it { expect(subject == described_class.new).to eq(true) }
    end

    context 'with different class' do
      it { expect(subject == Alchemrest::Response::Pipeline::ExtractPayload.new).to eq(false) }
    end
  end

  describe "eql?" do
    context 'with another instance' do
      it { expect(subject.eql?(described_class.new)).to eq(true) }
    end

    context 'with different class' do
      it { expect(subject.eql?(Alchemrest::Response::Pipeline::ExtractPayload.new)).to eq(false) }
    end
  end
end
