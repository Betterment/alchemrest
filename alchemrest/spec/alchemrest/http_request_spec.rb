# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::HttpRequest do
  let!(:api_request) do
    stub_request(:patch, "#{api_url}/api/v1/users/1")
      .with(body: expected_body, headers: expected_headers)
      .to_return(body: { name: "Jamie", age: 22 }.to_json)
  end

  let(:expected_body) do
    {}.to_json
  end

  let(:expected_headers) do
    {
      'User-Agent' => "Alchemrest/#{Alchemrest::VERSION}",
    }
  end

  let(:api_url) { client_class.configuration.connection.url }
  let(:client_class) do
    Class.new(Alchemrest::Client).tap do |klass|
      klass.configure do |config|
        config.service_name = 'example'
        config.connection.url = 'http://www.example.com'
        config.use_kill_switch(false)
        config.use_circuit_breaker(false)
      end
    end
  end

  let(:request_implementation) do
    Class.new(Alchemrest::Request) do
      disable_response_capture

      def path
        "/api/v1/users/1"
      end

      def http_method
        'patch'
      end

      def body
        {}.to_json
      end
    end
  end

  let(:request) { request_implementation.new }
  let(:client) { client_class.new }

  subject { described_class.new(request, client) }

  describe '#path' do
    it 'delegates to the request' do
      expect(subject.path).to eql('/api/v1/users/1')
    end
  end

  describe '#http_method' do
    it 'delegates to the request' do
      expect(subject.http_method).to eql('patch')
    end
  end

  describe '#body' do
    it 'delegates to the request' do
      expect(subject.body).to eql(expected_body)
    end
  end

  describe '#headers' do
    context 'with no header override' do
      it 'delegates to the request' do
        expect(subject.headers).to eql(expected_headers)
      end
    end

    context 'with a header override' do
      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          def headers
            { 'X-Test' => 'test' }
          end
        end
      end

      it 'delegates to the request' do
        expect(subject.headers).to eql(**expected_headers, 'X-Test' => 'test')
      end
    end

    context 'with a header override that conflicts with the default' do
      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          def headers
            { 'User-Agent' => 'overridden' }
          end
        end
      end

      it 'delegates to the request' do
        expect(subject.headers).to eql('User-Agent' => 'overridden')
      end
    end
  end

  describe '#url' do
    it 'returns the full url' do
      expect(subject.url).to eql("#{api_url}/api/v1/users/1")
    end
  end

  describe '#execute!' do
    it 'performs the request' do
      expect(api_request).not_to have_been_requested

      result = subject.execute!

      expect(api_request).to have_been_requested
      expect(result).to be_instance_of(Alchemrest::Result::Ok)

      response = result.unwrap_or_raise!

      expect(response).to be_a(Alchemrest::Response)
      expect(response.data).to eql("name" => "Jamie", "age" => 22)
    end

    context 'when the api call returns an error response' do
      let!(:api_request) do
        stub_request(:patch, "#{api_url}/api/v1/users/1")
          .with(body: expected_body, headers: expected_headers)
          .to_return(status: 400, body: { error: "Invalid" }.to_json)
      end

      it "returns an error result" do
        expect(api_request).not_to have_been_requested

        result = subject.execute!

        expect(api_request).to have_been_requested
        expect(result).to be_instance_of(Alchemrest::Result::Error)
      end
    end

    context 'when the api call times out' do
      let!(:api_request) do
        stub_request(:patch, "#{api_url}/api/v1/users/1")
          .with(body: expected_body, headers: expected_headers)
          .to_timeout
      end

      it "returns an error result wrapping a timeout error" do
        expect(api_request).not_to have_been_requested

        result = subject.execute!
        result => {error:}

        expect(api_request).to have_been_requested
        expect(result).to be_instance_of(Alchemrest::Result::Error)
        expect(error).to be_instance_of(Alchemrest::TimeoutError)
      end
    end

    context 'when the api call raises some other faraday error' do
      let!(:api_request) do
        stub_request(:patch, "#{api_url}/api/v1/users/1")
          .with(body: expected_body, headers: expected_headers)
          .to_raise(Faraday::SSLError.new(OpenSSL::SSL::SSLError.new))
      end

      it "returns an error result wrapping a request failed error" do
        expect(api_request).not_to have_been_requested

        result = subject.execute!
        result => {error:}

        expect(api_request).to have_been_requested
        expect(result).to be_instance_of(Alchemrest::Result::Error)
        expect(error).to be_instance_of(Alchemrest::RequestFailedError)
        expect(error.cause).to be_instance_of(Faraday::SSLError)
      end
    end

    context 'when the api call raises some other rescuable exception' do
      let!(:api_request) do
        stub_request(:patch, "#{api_url}/api/v1/users/1")
          .with(body: expected_body, headers: expected_headers)
          .to_raise(Alchemrest::KillSwitchEnabledError)
      end

      it "returns an error result wrapping the error" do
        expect(api_request).not_to have_been_requested

        result = subject.execute!
        result => {error:}

        expect(api_request).to have_been_requested
        expect(result).to be_instance_of(Alchemrest::Result::Error)
        expect(error).to be_instance_of(Alchemrest::KillSwitchEnabledError)
      end
    end

    context "when the circuit breaker is enabled" do
      let(:client_class) do
        breaker = mock_breaker
        Class.new(Alchemrest::Client).tap do |klass|
          klass.configure do |config|
            config.service_name = 'example'
            config.connection.url = 'http://www.example.com'
            config.use_circuit_breaker(breaker)
            config.use_kill_switch(false)
          end
        end
      end
      let(:mock_breaker) { mock_breaker_class.new(open) }
      let(:mock_breaker_class) do
        Class.new(Alchemrest::CircuitBreaker) do
          def initialize(open)
            @open = open
            super(service_name: 'dummy')
          end

          def open? = @open
        end
      end

      context "and the circuit breaker is not open" do
        let(:open) { false }
        it "has the circuit breaker monitor the response" do
          expect(mock_breaker).to receive(:monitor!).with(result: an_instance_of(Alchemrest::Result::Ok))

          subject.execute!
        end
      end

      context "and the circuit breaker is open" do
        let(:open) { true }
        it "has the circuit breaker it returns the open circuit error" do
          result = subject.execute!
          expect(result).to be_instance_of(Alchemrest::Result::Error)
          result => { error: }
          expect(error).to be_instance_of(Alchemrest::CircuitOpenError)
        end
      end
    end

    context "for a GET request" do
      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          disable_response_capture

          def path
            "/api/v1/users"
          end

          def http_method
            'get'
          end
        end
      end

      let!(:api_request) do
        stub_request(:get, "#{api_url}/api/v1/users")
          .with(body: nil)
          .to_return(body: [{ name: "Jamie", age: 22 }, { name: "Fred", age: 19 }].to_json)
      end

      it "executes" do
        expect(api_request).not_to have_been_requested

        result = subject.execute!

        expect(api_request).to have_been_requested
        response = result.unwrap_or_raise!

        expect(response).to be_a(Alchemrest::Response)
        expect(response.data).to eql([{ "name" => "Jamie", "age" => 22 }, { "name" => "Fred", "age" => 19 }])
      end
    end
  end
end
