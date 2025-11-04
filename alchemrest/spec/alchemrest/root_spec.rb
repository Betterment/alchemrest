# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Root do
  let!(:user_request) do
    stub_const("GetUser", Class.new(Alchemrest::Request) do
      disable_response_capture

      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      endpoint :get, '/v1/users/:id' do |url|
        url.values = { id: @id }
      end
    end)
  end

  let!(:client_class) do
    stub_const("ApiClient", Class.new(Alchemrest::Client) do
      const_set("API_URL", 'http://www.example.com')

      configure do |config|
        config.connection.url = self::API_URL
        config.use_circuit_breaker(true)
        config.use_kill_switch(true)
      end
    end)
  end

  let!(:all_users_request) do
    stub_const("GetAllUsers", Class.new(Alchemrest::Request) do
      attr_reader :args

      disable_response_capture

      def initialize(**args) # rubocop:disable Lint/MissingSuper
        @args = args
      end

      endpoint :get, '/v1/users' do |url|
        url.query = args
      end
    end)
  end

  let(:implementation) do
    Class.new(Alchemrest::Root) do
      attr_reader :id

      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      def client
        ApiClient.new
      end
    end
  end

  let(:api_url) { ApiClient::API_URL }
  let(:user_id) { 1 }
  subject { implementation.new(id: user_id) }

  describe '.define_request' do
    context 'a request with default params' do
      let!(:get_user_request_stub) do
        stub_request(:get, "#{api_url}/v1/users/#{user_id}")
          .to_return(status: 200, body: "", headers: {})
      end

      it 'has a method named `get_user` and calls the user endpoint with the id path param' do
        subject.class.define_request(:get_user, GetUser) { |request| request.defaults = { id: } }
        expect(subject.class.request_definitions[:get_user]).to have_attributes(name: :get_user)

        result = subject.get_user
        expect(get_user_request_stub).to have_been_requested
        expect(result).to be_kind_of(Alchemrest::Result::Ok)

        unwrapped_result = result.unwrap_or_raise!
        expect(unwrapped_result).to be_kind_of(Alchemrest::Response)
      end
    end

    context 'a request with no params' do
      let!(:all_users_request_stub) do
        stub_request(:get, "#{api_url}/v1/users")
          .to_return(status: 200, body: "", headers: {})
      end

      it 'has a method named `all_users` and calling it executes the api request' do
        subject.class.define_request(:all_users, GetAllUsers)

        expect(subject.class.request_definitions[:all_users]).to have_attributes(name: :all_users)
        result = subject.all_users
        expect(all_users_request_stub).to have_been_requested
        expect(result).to be_kind_of(Alchemrest::Result::Ok)

        unwrapped_result = result.unwrap_or_raise!
        expect(unwrapped_result).to be_kind_of(Alchemrest::Response)
      end

      context "when invoked with parameters" do
        let!(:all_users_request_stub) do
          stub_request(:get, "#{api_url}/v1/users?name=BetterBoyer")
            .to_return(status: 200, body: "", headers: {})
        end

        it 'passes the params through and appends them as query strings to the request' do
          subject.class.define_request(:all_users, GetAllUsers)

          result = subject.all_users(name: 'BetterBoyer')
          expect(all_users_request_stub).to have_been_requested
          expect(result).to be_kind_of(Alchemrest::Result::Ok)

          unwrapped_result = result.unwrap_or_raise!
          expect(unwrapped_result).to be_kind_of(Alchemrest::Response)
        end
      end

      context "when the request returns an error" do
        let!(:all_users_request_stub) do
          stub_request(:get, "#{api_url}/v1/users?name=BetterBoyer")
            .to_return(status: 400)
        end

        it 'returns the error' do
          subject.class.define_request(:all_users, GetAllUsers)

          result = subject.all_users(name: 'BetterBoyer')
          expect(result).to be_kind_of(Alchemrest::Result::Error)
        end
      end
    end

    context 'with an inherited root' do
      subject { Class.new(implementation).new(id: user_id) }
      let!(:get_user_request) do
        stub_request(:get, "#{api_url}/v1/users/#{user_id}")
          .to_return(status: 200, body: "", headers: {})
      end

      it 'can use requests defined on the superclass' do
        implementation.define_request(:get_user, GetUser) { |request| request.defaults = { id: } }

        result = subject.get_user
        expect(get_user_request).to have_been_requested
        expect(result).to be_kind_of(Alchemrest::Result::Ok)

        unwrapped_result = result.unwrap_or_raise!
        expect(unwrapped_result).to be_kind_of(Alchemrest::Response)
      end
    end

    context 'with an error handler defined' do
      let(:errors) { [] }
      let!(:all_users_request_stub) do
        stub_request(:get, "#{api_url}/v1/users")
          .to_return(status: 403)
      end

      before do
        error_collection = errors
        implementation.define_request :all_users, GetAllUsers
        implementation.on_alchemrest_error do |error|
          error => { status: }
          error_collection << status
        end
      end

      it "runs the handler when the endpoint returns an error" do
        expect { subject.all_users }.to change { errors.count }.from(0).to(1)
        expect(errors).to eq([403])
      end

      context "with an inherited root" do
        subject { Class.new(implementation).new(id: user_id) }

        it "runs the handler when the endpoint returns an error" do
          expect { subject.all_users }.to change { errors.count }.from(0).to(1)
          expect(errors).to eq([403])
        end
      end
    end
  end

  describe '#client' do
    let(:implementation) do
      Class.new(Alchemrest::Root) do
        define_request :all_users, GetAllUsers
      end
    end
    before { stub_const("MissingClient", implementation) }
    subject { implementation.new }

    it 'raises an error when the client is not defined' do
      expect { subject.all_users }.to raise_error(
        Alchemrest::UndefinedClientError,
        /You forgot to specify a client.+MissingClient < Alchemrest::Root/m,
      )
    end
  end

  describe '.use_client' do
    let(:implementation) do
      Class.new(described_class)
    end
    subject { implementation.new }

    it 'overrides the default implementation for #client' do
      implementation.use_client(ApiClient)
      expect(subject.client).to be_an_instance_of(ApiClient)
    end
  end

  describe '.on_alchemrest_error' do
    let(:block) { ->(error) { puts error } }
    it "sets the error handler" do
      implementation.on_alchemrest_error(&block)
      expect(implementation.error_handler).to eq(block)
    end
  end

  describe "self.error_handler" do
    context 'when not defined' do
      it 'is nil' do
        expect(implementation.error_handler).to eq(nil)
      end
    end

    context 'when defined on super class' do
      let(:block) { ->(error) { puts error } }

      subject { Class.new(implementation).new(id: user_id) }

      it 'is nil' do
        implementation.on_alchemrest_error(&block)

        expect(subject.class.error_handler).to eq(block)
      end
    end
  end

  describe '.reset_error_handler!' do
    let(:block) { ->(error) { puts error } }
    it "sets the error handler" do
      implementation.on_alchemrest_error(&block)
      implementation.reset_error_handler!

      expect(implementation.error_handler).to eq(nil)
    end

    context 'when defined on super class' do
      let(:block) { ->(error) { puts error } }
      let(:block_2) { ->(error) { puts error.class } }

      subject { Class.new(implementation).new(id: user_id) }

      it 'is resets to the original super class value' do
        implementation.on_alchemrest_error(&block)
        subject.class.on_alchemrest_error(&block_2)

        subject.class.reset_error_handler!

        expect(subject.class.error_handler).to eq(block)
      end
    end
  end
end
