# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::WebmockHelpers do
  describe 'self.stub_alchemrest_request' do
    subject { stub_alchemrest_request(request, **options) }

    let(:options) { {} }

    context 'with a Alchemrest::Request object for a get request' do
      let(:request) { BankApi::Requests::GetUser.new(id: 1) }

      it 'creates a stub with the right uri pattern' do
        expect(subject).to be_a(WebMock::RequestStub)
        expect(subject.request_pattern.uri_pattern.to_s).to eq('"http://{host}/api/v1/users/1?includeDetails=true"')
        expect(subject.request_pattern.method_pattern.matches?(:get)).to eq(true)
        expect(subject.request_pattern.body_pattern).to be_nil
        expect(subject.request_pattern.headers_pattern).to be_nil
      end
    end

    context "with a Alchemrest::HttpRequest object for a get request" do
      let(:client) { BankApi::Client.new }
      let(:request) { client.build_http_request(BankApi::Requests::GetUser.new(id: 1)) }

      it 'creates a stub with the right uri pattern' do
        expect(subject).to be_a(WebMock::RequestStub)
        expect(subject.request_pattern.uri_pattern.to_s).to eq('http://bank.example.com/api/v1/users/1?includeDetails=true')
        expect(subject.request_pattern.method_pattern.matches?(:get)).to eq(true)
        expect(subject.request_pattern.body_pattern).to be_nil
        expect(subject.request_pattern.headers_pattern).to be_nil
      end
    end

    context 'with a Alchemrest::Request object for a post request' do
      let(:request) { BankApi::Requests::PostTransaction.new(id: 1, account_id: 2, amount: 100) }

      it 'creates a stub with the right uri pattern' do
        expect(subject).to be_a(WebMock::RequestStub)
        expect(subject.request_pattern.uri_pattern.to_s).to eq('"http://{host}/api/v1/users/1/accounts/2/transactions"')
        expect(subject.request_pattern.method_pattern.matches?(:post)).to eq(true)
        expect(subject.request_pattern.body_pattern).to be_nil
        expect(subject.request_pattern.headers_pattern).to be_nil
      end
    end

    context 'with a Alchemrest::Request object for a post request using the `with_body: true` option' do
      let(:request) { BankApi::Requests::PostTransaction.new(id: 1, account_id: 2, amount: 100) }
      let(:options) { { with_request_body: true } }

      it 'creates a stub with the right uri pattern' do
        expect(subject).to be_a(WebMock::RequestStub)
        expect(subject.request_pattern.uri_pattern.to_s).to eq('"http://{host}/api/v1/users/1/accounts/2/transactions"')
        expect(subject.request_pattern.method_pattern.matches?(:post)).to eq(true)
        expect(subject.request_pattern.body_pattern.pattern).to eq({ "amount" => 100 })
        expect(subject.request_pattern.headers_pattern).to be_nil
      end
    end

    context 'with a Alchemrest::Request object for a get request using `with_headers: true` option' do
      let(:request) { BankApi::Requests::GetBusinessAccount.new(id: 1, token: "A_TOKEN") }
      let(:options) { { with_headers: true } }

      it 'creates a stub with the right uri pattern' do
        expect(subject).to be_a(WebMock::RequestStub)
        expect(subject.request_pattern.uri_pattern.to_s).to eq('"http://{host}/api/business_accounts/1"')
        expect(subject.request_pattern.method_pattern.matches?(:get)).to eq(true)
        expect(subject.request_pattern.headers_pattern.to_s).to eq("{'Authorization'=>'Bearer A_TOKEN'}")
        expect(subject.request_pattern.body_pattern).to be_nil
      end
    end

    context 'with a Alchemrest::Request object that overrides `def http_method` and uses a string value' do
      let(:request) do
        implementation = Class.new(Alchemrest::Request) do
          def initialize(id)
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
        implementation.new(1)
      end

      it 'creates a stub with the right uri pattern' do
        expect(subject).to be_a(WebMock::RequestStub)
        expect(subject.request_pattern.uri_pattern.to_s).to eq('"http://{host}/api/v1/users/1"')
        expect(subject.request_pattern.method_pattern.matches?(:get)).to eq(true)
        expect(subject.request_pattern.headers_pattern).to be_nil
        expect(subject.request_pattern.body_pattern).to be_nil
      end
    end
  end
end
