# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::ResponseError do
  let(:raw_response) do
    instance_double(
      Faraday::Response,
      status: 503,
      success?: false,
      body: {},
      env: instance_double(Faraday::Env, url: "http://test.com/api/users", method: :get),
    )
  end

  let(:response) { Alchemrest::Response.new(raw_response) }

  subject { described_class.new(response) }

  describe "#to_s" do
    it "has a string with error details" do
      expect(subject.to_s).to eq "HTTP 503 for GET http://test.com/api/users - Error with HTTP status: 503"
    end
  end

  describe "#deconstruct" do
    it "pulls out the status and the error details" do
      expect(subject.deconstruct).to eq([503, 'Error with HTTP status: 503'])
    end
  end

  describe "#deconstruct_keys" do
    it "pulls out the status and the error details" do
      expect(subject.deconstruct_keys(nil)).to eq({ status: 503, error: 'Error with HTTP status: 503' })
    end
  end
end
