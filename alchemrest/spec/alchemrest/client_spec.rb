# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Client do
  let(:api_url) { client_class.configuration.connection.url }
  let(:client_class) do
    Class.new(described_class).tap do |klass|
      klass.configure do |config|
        config.service_name = 'example'
        config.connection.url = 'http://www.example.com'
        config.use_circuit_breaker(false)
        config.use_kill_switch(false)
      end
    end
  end

  let(:request_implementation) do
    Class.new(Alchemrest::Request) do
      disable_response_capture

      def initialize(id)
        @id = id
      end

      def path
        "/api/v1/users/#{@id}"
      end

      def http_method
        'get'
      end
    end
  end

  subject { client_class.new }

  describe "self.configure" do
    context "with a minimally configured client" do
      let!(:api_request) do
        stub_alchemrest_request(request)
          .to_return(body: { name: "Jamie", age: 22 }.to_json)
      end

      let(:request) { request_implementation.new(1) }

      it "can execute requests" do
        expect(subject.build_http_request(request).execute!.unwrap_or_raise!.data).to eq({ "name" => "Jamie", "age" => 22 })
        expect(api_request).to have_been_requested
      end
    end

    context "with an extensively configured client" do
      let(:client) do
        Class.new(described_class).tap do |klass|
          klass.configure do |config|
            config.connection.url = 'http://www.example.com'
            config.connection.headers = { 'X-Auth': "foo" }
            config.use_circuit_breaker(false)
            config.use_kill_switch(false)
            config.connection.customize(use_default_middleware: false) do |c|
              c.options[:open_timeout] = 30
              c.options[:timeout] = 30
              c.use Alchemrest::FaradayMiddleware::UnderScoreResponse
              c.use Alchemrest::FaradayMiddleware::JsonParser
              c.use Alchemrest::FaradayMiddleware::ExternalApiInstrumentation, external_service: "test"
            end
          end
        end
      end

      let!(:api_request) do
        stub_request(:get, "#{api_url}/api/v1/users/1")
          .to_return(body: { name: "Jamie", age: 22 }.to_json)
      end

      let(:request) { request_implementation.new(1) }

      it "can execute requests" do
        expect(subject.build_http_request(request).execute!.unwrap_or_raise!.data).to eq({ "name" => "Jamie", "age" => 22 })
        expect(api_request).to have_been_requested
      end
    end
  end

  describe '.kill_switch' do
    it 'returns an Alchemrest::KillSwitch' do
      expect(client_class.kill_switch).to be_a(Alchemrest::KillSwitch)
    end

    it 'returns an instance with the proper service name' do
      expect(client_class.kill_switch.service_name).to eq(client_class.configuration.service_name)
    end
  end

  describe "#build_http_request" do
    let!(:api_request) do
      stub_request(:get, "#{api_url}/api/v1/users/1")
        .to_return(body: { name: "Jamie", age: 22 }.to_json)
    end

    let(:request) { request_implementation.new(1) }

    it "returns an instance of Alchemrest::HttpRequest" do
      expect(subject.build_http_request(request)).to be_a(Alchemrest::HttpRequest)
    end

    it "has the expected request state" do
      expect(subject.build_http_request(request)).to have_attributes(
        url: "#{api_url}/api/v1/users/1",
        body: nil,
        headers: { "User-Agent" => "Alchemrest/#{Alchemrest::VERSION}" },
      )
    end

    it "creates an executable request" do
      expect(subject.build_http_request(request).execute!.unwrap_or_raise!.data).to eq({ "name" => "Jamie", "age" => 22 })
      expect(api_request).to have_been_requested
    end

    context "when the api request times out" do
      let!(:api_request) do
        stub_request(:get, "#{api_url}/api/v1/users/1")
          .to_timeout
      end

      it "builds an executable request that returns a result wrapping the timeout error" do
        subject.build_http_request(request).execute! => Alchemrest::Result::Error(error)
        expect(error).to be_kind_of(Alchemrest::RequestFailedError)
      end
    end

    context "with an overriden #transform_response" do
      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          def initialize(id)
            @id = id
          end

          def path
            "/api/v1/users/#{@id}"
          end

          def http_method
            'get'
          end

          def transform_response(response)
            if response.success?
              Alchemrest::Result::Ok("Ok")
            else
              Alchemrest::Result::Error("Bad")
            end
          end
        end
      end

      context "for a successful request" do
        it "builds a customized Ok result using #transform_response" do
          expect(subject.build_http_request(request).execute!.unwrap_or_raise!).to eq("Ok")
        end
      end

      context "for a request with an http error" do
        let!(:api_request) do
          stub_request(:get, "#{api_url}/api/v1/users/1")
            .to_return(status: 503, body: {}.to_json)
        end

        it "builds a customized Error result using #transform_response" do
          expect { subject.build_http_request(request).execute!.unwrap_or_raise! }.to raise_error("Bad")
        end
      end
    end
  end

  describe "#build_response" do
    let(:raw_response) do
      instance_double(
        Faraday::Response,
        status:,
        success?: success,
        body:,
      )
    end

    let(:status) { 200 }
    let(:success) { true }
    let(:body) { { foo: "bar" } }

    it "creates a response object from the response data" do
      expect(subject.build_response(raw_response)).to be_a(Alchemrest::Response)
    end
  end

  describe '#configuration' do
    it "has the configuration available at the instance level" do
      expect(subject.configuration).to eq(subject.class.configuration)
    end
  end
end
