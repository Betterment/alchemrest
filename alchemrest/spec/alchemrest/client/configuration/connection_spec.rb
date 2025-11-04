# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Client::Configuration::Connection do
  subject { client_configuration.connection }

  let(:client_configuration) { Alchemrest::Client::Configuration.new }

  context "when we've set a url" do
    before do
      client_configuration.connection.url = "https://test.com/"
    end

    it "allows us to freeze" do
      expect { subject.freeze }.not_to raise_error
    end
  end

  context "when we haven't set a url" do
    it "raises when we try to freeze" do
      expect { subject.freeze }.to raise_error Alchemrest::InvalidConfigurationError, "No url provided"
    end
  end

  describe "#create_new_connection" do
    context "when we haven't frozen the config" do
      before do
        client_configuration.connection.url = "https://test.com/"
      end

      it "raises" do
        expect { subject.create_new_connection }.to raise_error(
          Alchemrest::ConfigurationNotReadyError,
          "Don't use configuration to build connections until the configuration has been frozen",
        )
      end
    end

    context "when we've set only the url" do
      before do
        client_configuration.connection.url = "https://test.com/"
        subject.freeze
      end

      it "creates a connection with the right settings" do
        connection = subject.create_new_connection
        expect(connection.url_prefix.to_s).to eq("https://test.com/")
        expect(connection.adapter).to eq(Faraday::Adapter::NetHttp)
        expect(connection.builder.handlers.map(&:name))
          .to contain_exactly(
            "Faraday::Request::Json",
            "Alchemrest::FaradayMiddleware::UnderScoreResponse",
            "Alchemrest::FaradayMiddleware::JsonParser",
          )
      end
    end

    context "when we've set the url and headers" do
      before do
        client_configuration.connection.url = "https://test.com/"
        client_configuration.connection.headers = { 'X-Auth': "foo" }
        subject.freeze
      end

      it "creates a connection with the right settings" do
        connection = subject.create_new_connection
        expect(connection.url_prefix.to_s).to eq("https://test.com/")
        expect(connection.headers).to include({ 'X-Auth': "foo" })
        expect(connection.builder.handlers.map(&:name))
          .to contain_exactly(
            "Faraday::Request::Json",
            "Alchemrest::FaradayMiddleware::UnderScoreResponse",
            "Alchemrest::FaradayMiddleware::JsonParser",
          )
      end
    end

    context "when we provide a service name on the client connection" do
      before do
        client_configuration.connection.url = "https://test.com/"
        client_configuration.connection.headers = { 'X-Auth': "foo" }
        client_configuration.service_name = "test"
        subject.freeze
      end

      it "creates a connection with the right settings" do
        connection = subject.create_new_connection
        expect(connection.url_prefix.to_s).to eq("https://test.com/")
        expect(connection.headers).to include({ 'X-Auth': "foo" })
        expect(connection.builder.handlers.map(&:name))
          .to eq([
            "Faraday::Request::Json",
            "Alchemrest::FaradayMiddleware::ExternalApiInstrumentation",
            "Alchemrest::FaradayMiddleware::UnderScoreResponse",
            "Alchemrest::FaradayMiddleware::JsonParser",
          ])

        external_api_instrumentation_handler = connection.builder.handlers
          .find { |h| h.name == "Alchemrest::FaradayMiddleware::ExternalApiInstrumentation" }

        expect(external_api_instrumentation_handler.build.external_service).to eq("test")
      end
    end

    context 'when we opt in to kill switch' do
      before do
        client_configuration.connection.url = "https://test.com/"
        client_configuration.connection.headers = { 'X-Auth': "foo" }
        client_configuration.service_name = "test"
        client_configuration.use_kill_switch(true)
        allow(Alchemrest.kill_switch_adapter).to receive(:ready?).and_return(true)
        subject.freeze
      end

      it "creates a connection with the right settings" do
        connection = subject.create_new_connection
        expect(connection.url_prefix.to_s).to eq("https://test.com/")
        expect(connection.headers).to include({ 'X-Auth': "foo" })
        expect(connection.builder.handlers.map(&:name))
          .to eq([
            "Faraday::Request::Json",
            "Alchemrest::FaradayMiddleware::KillSwitch",
            "Alchemrest::FaradayMiddleware::ExternalApiInstrumentation",
            "Alchemrest::FaradayMiddleware::UnderScoreResponse",
            "Alchemrest::FaradayMiddleware::JsonParser",
          ])

        kill_switch_handler = connection.builder.handlers
          .find { |h| h.name == "Alchemrest::FaradayMiddleware::KillSwitch" }

        expect(kill_switch_handler.build.service_name).to eq("test")
      end

      context 'when the kill switch adapter is not ready' do
        before do
          allow(Alchemrest.kill_switch_adapter).to receive(:ready?).and_return(false)
        end

        it 'it does not include the kill switch middleware' do
          connection = subject.create_new_connection
          expect(connection.url_prefix.to_s).to eq("https://test.com/")
          expect(connection.headers).to include({ 'X-Auth': "foo" })
          expect(connection.builder.handlers.map(&:name))
            .to eq([
              "Faraday::Request::Json",
              "Alchemrest::FaradayMiddleware::ExternalApiInstrumentation",
              "Alchemrest::FaradayMiddleware::UnderScoreResponse",
              "Alchemrest::FaradayMiddleware::JsonParser",
            ])
        end
      end
    end

    context "when we call customize" do
      let(:custom_middleware) do
        Class.new(Faraday::Middleware) do
          def call(env)
            env.request_headers['X-Test'] = "foo"
            @app.call(env)
          end
        end
      end

      before do
        stub_const("CustomMiddleware", custom_middleware)
        client_configuration.connection.url = "https://test.com/"
        client_configuration.connection.headers = { 'X-Auth': "foo" }
        client_configuration.service_name = "test"
        client_configuration.connection.customize do |c|
          c.options[:timeout] = 30
          c.use CustomMiddleware
        end
        subject.freeze
      end

      it "creates a connection with the right settings" do
        connection = subject.create_new_connection
        expect(connection.url_prefix.to_s).to eq("https://test.com/")
        expect(connection.headers).to include({ 'X-Auth': "foo" })
        expect(connection.builder.handlers.map(&:name))
          .to eq([
            "Faraday::Request::Json",
            "CustomMiddleware",
            "Alchemrest::FaradayMiddleware::ExternalApiInstrumentation",
            "Alchemrest::FaradayMiddleware::UnderScoreResponse",
            "Alchemrest::FaradayMiddleware::JsonParser",
          ])

        expect(connection.options[:timeout]).to eq(30)
      end
    end

    context "when we call customize(use_default_middleware: false)" do
      before do
        client_configuration.connection.url = "https://test.com/"
        client_configuration.connection.headers = { 'X-Auth': "foo" }
        client_configuration.connection.customize(use_default_middleware: false) do |c|
          c.options[:timeout] = 30
        end
        subject.freeze
      end

      it "creates a connection with the right settings" do
        connection = subject.create_new_connection
        expect(connection.url_prefix.to_s).to eq("https://test.com/")
        expect(connection.headers).to include({ 'X-Auth': "foo" })
        expect(connection.builder.handlers.map(&:name))
          .to eq(["Faraday::Request::Json"])

        expect(connection.options[:timeout]).to eq(30)
      end
    end

    context "when we opt out of the underscore response keys on the client connection" do
      before do
        client_configuration.connection.url = "https://test.com/"
        client_configuration.connection.headers = { 'X-Auth': "foo" }
        client_configuration.underscore_response_body_keys = false
        subject.freeze
      end

      it "creates a connection with the right settings" do
        connection = subject.create_new_connection
        expect(connection.url_prefix.to_s).to eq("https://test.com/")
        expect(connection.headers).to include({ 'X-Auth': "foo" })
        expect(connection.builder.handlers.map(&:name))
          .to contain_exactly(
            "Faraday::Request::Json",
            "Alchemrest::FaradayMiddleware::JsonParser",
          )
      end
    end
  end
end
