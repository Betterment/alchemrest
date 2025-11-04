# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe Alchemrest::Request do
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
  let(:body) { {} }

  let(:response) { Alchemrest::Response.new(raw_response) }

  subject { implementation.new(1) }

  describe "#transform_response" do
    let(:implementation) do
      Class.new(Alchemrest::Request) do
        disable_response_capture

        def initialize(id)
          @id = id
        end

        def path
          "/v1/users#{@id}"
        end

        def http_method
          'get'
        end
      end
    end

    context "for a successful response" do
      let(:status) { 200 }
      let(:success) { true }

      it "properly converts the response to an Ok result" do
        expect(subject.transform_response(response)).to eq(Alchemrest::Result.Ok(response))
      end
    end

    context "for a failed response" do
      let(:status) { 503 }
      let(:success) { false }

      it "properly converts the response to an Error result" do
        expect { subject.transform_response(response).unwrap_or_raise! }.to raise_error(Alchemrest::ServerError)
      end
    end

    context "with a custom transformer" do
      let(:status) { 200 }
      let(:success) { true }

      let(:implementation) do
        Class.new(Alchemrest::Request) do
          disable_response_capture

          def response_transformer
            lambda { |response| response.status }
          end
        end
      end

      subject { implementation.new }

      it "uses the #response_transformer" do
        expect(subject.transform_response(response)).to eq(200)
      end
    end

    context "with response capture enabled" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          enable_response_capture
          endpoint :get, '/v1/users/'

          def initialize(id)
            @id = id
          end
        end
      end

      it "calls Alchemrest.handle_captured_response" do
        subject.transform_response(response)
        expect(captured_responses.size).to eq(1)
      end
    end

    context "with response capture disabled" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          disable_response_capture

          def initialize(id)
            @id = id
          end
        end
      end

      it "does not capture the responses" do
        subject.transform_response(response)
        expect(captured_responses.size).to eq(0)
      end
    end
  end

  describe ".returns" do
    before do
      allow(Alchemrest).to receive(:parameter_filter)
        .and_return(ActiveSupport::ParameterFilter.new(%i(name age)))

      stub_const("User", Class.new(Alchemrest::Data) do
        schema do |s|
          {
            required: {
              name: s.string,
              age: s.integer,
              employer: s.string,
            },
          }
        end

        configure_response_capture do
          omitted :employer
          safe :age
        end
      end)

      stub_const("Group", Class.new(Alchemrest::Data) do
        schema do |s|
          {
            required: {
              name: s.string,
              users: s.many_of(User),
            },
          }
        end

        configure_response_capture do
          safe :name
        end
      end)
    end

    let(:body) do
      {
        "name" => "Group Name",
        "users" => [
          {
            "name" => "User 1",
            "age" => 20,
            "employer" => "Company 1",
          },
          {
            "name" => "User 2",
            "age" => 30,
            "employer" => "Company 2",
          },
        ],
      }
    end

    let(:implementation) do
      Class.new(Alchemrest::Request) do
        returns Group

        enable_response_capture

        def initialize(id)
          @id = id
        end

        def path
          "/v1/users#{@id}"
        end

        def http_method
          'get'
        end
      end
    end

    context "for a successful response" do
      it "properly converts the response to an Ok result and uses the capture lambda" do
        expect(subject.transform_response(response).unwrap_or_raise!).to be_a(Group)
        expect(captured_responses.size).to eq(1)
        expect(captured_responses.first)
          .to include({
                        data: {
                          name: "Group Name",
                          users: [
                            {
                              name: "[FILTERED]",
                              age: 20,
                            },
                            {
                              name: "[FILTERED]",
                              age: 30,
                            },
                          ],
                        },
                      })
      end
    end

    context "for an error response" do
      let(:status) { 400 }
      let(:success) { false }
      let(:body) do
        {
          "error" => "Bad Request",
        }
      end

      it "converts the response to an Error result and uses the capture lambda" do
        result = subject.transform_response(response)
        result => { error: }

        expect(result).to be_a(Alchemrest::Result::Error)
        expect(error).to be_a(Alchemrest::ClientError)
        expect(captured_responses.size).to eq(1)
        expect(captured_responses.first).to include({ data: body.deep_symbolize_keys })
      end
    end

    context "for an empty reponse" do
      let(:status) { 204 }
      let(:success) { true }
      let(:body) do
        ''
      end
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          returns Group, allow_empty_response: true

          enable_response_capture

          def initialize(id)
            @id = id
          end

          def path
            "/v1/users#{@id}"
          end

          def http_method
            'get'
          end
        end
      end

      it "converts the response to an Error result and uses the capture lambda" do
        result = subject.transform_response(response)
        result => { value: }

        expect(result).to be_a(Alchemrest::Result::Ok)
        expect(value).to eq(nil)
        expect(captured_responses.size).to eq(1)
        expect(captured_responses.first).to include({ data: nil })
      end
    end

    context "with :path_to_payload" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          returns Group, path_to_payload: %i(data group)

          enable_response_capture

          def initialize(id)
            @id = id
          end

          def path
            "/v1/users/#{@id}"
          end

          def http_method
            'get'
          end
        end
      end

      context "for a successful response" do
        let(:body) do
          {
            "data" => {
              "group" => {
                "name" => "Group Name",
                "users" => [
                  {
                    "name" => "User 1",
                    "age" => 20,
                    "employer" => "Company 1",
                  },
                  {
                    "name" => "User 2",
                    "age" => 30,
                    "employer" => "Company 2",
                  },
                ],
              },
            },
            "status" => { "code" => 200, "msg" => "OK" },
          }
        end

        it "properly converts the response to an Ok result and uses the capture lambda" do
          expect(subject.transform_response(response).unwrap_or_raise!).to be_a(Group)
          expect(captured_responses.size).to eq(1)
          expect(captured_responses.first)
            .to include({
                          data: {
                            data: {
                              group: {
                                name: "Group Name",
                                users: [
                                  {
                                    name: "[FILTERED]",
                                    age: 20,
                                  },
                                  {
                                    name: "[FILTERED]",
                                    age: 30,
                                  },
                                ],
                              },
                            },
                            status: { code: 200, msg: "OK" },
                          },
                        })
        end
      end

      context "for an error response" do
        let(:status) { 400 }
        let(:body) do
          {
            "error" => "Bad Request",
          }
        end

        it "converts the response to an Error result and uses the capture lambda" do
          expect(subject.transform_response(response)).to be_a(Alchemrest::Result::Error)
          expect(captured_responses.size).to eq(1)
          expect(captured_responses.first).to include(data: body.deep_symbolize_keys)
        end
      end
    end

    context "with :allows_empty reponse" do
      let(:status) { 204 }
      let(:success) { true }
      let(:body) do
        ''
      end

      it "converts to a nil and users to capture lambda" do
        result = subject.transform_response(response)
        result => { error: }

        expect(result).to be_a(Alchemrest::Result::Error)
        expect(error).to be_a(Alchemrest::ResponsePipelineError)
        expect(captured_responses.size).to eq(1)
        expect(captured_responses.first).to include({ data: nil })
      end
    end
  end

  describe ".endpoint" do
    subject { implementation.new }

    context "with static endpoint declaration" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          endpoint :get, '/v1/users/'
        end
      end

      it "sets up a template and http method" do
        expect(subject.path).to eq('/v1/users/')
        expect(subject.http_method).to eq('get')
      end
    end

    context "with invalid http_method declaration" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          endpoint :invalid_method, "/v1/users/"
        end
      end

      it "raises error" do
        expect { implementation.new }.to raise_error(ArgumentError, 'must provide a valid HTTP method')
      end
    end

    context "with an invalid non string template value" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          endpoint :get, :v_1
        end
      end

      it "raises error" do
        expect { implementation.new }.to raise_error(ArgumentError, 'template must be string')
      end
    end

    context "with a blank template value" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          endpoint :get, ''
        end
      end

      it "raises error" do
        expect { implementation.new }.to raise_error(ArgumentError, 'missing template')
      end
    end

    context "when template uses class instance variables with an interpolated string" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          def initialize(user_object:)
            @user_object = user_object
          end

          endpoint get: "/v1/users/#{@user_object.id}"
        end
      end

      subject { implementation.new(user_object: OpenStruct.new({ id: 123 })) }

      it "raises error because class instance variable is not available" do
        expect { subject }.to raise_error(NoMethodError, "undefined method `id' for nil:NilClass")
      end
    end

    context "when we have a valid template" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          def initialize(user_object:)
            @user_object = user_object
          end

          endpoint :get, "/v1/users/:id" do |url|
            url.values = { id: @user_object.id }
          end
        end
      end

      subject { implementation.new(user_object: OpenStruct.new({ id: 123 })) }

      it "path returns the final string" do
        expect(subject.path).to eq('/v1/users/123')
      end
    end
  end

  describe ".enable_response_capture" do
    context "when not used" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          def initialize(id)
            @id = id
          end
        end
      end

      it "makes `response_capture_enable` -> true for instances" do
        expect(subject.response_capture_enabled).to be(true)
      end
    end

    context "when used" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          enable_response_capture

          def initialize(id)
            @id = id
          end
        end
      end

      it "makes `response_capture_enable` -> true for instances" do
        expect(subject.response_capture_enabled).to be(true)
      end
    end

    context "when to override base class" do
      let(:base) do
        Class.new(Alchemrest::Request) do
          disable_response_capture

          def initialize(id)
            @id = id
          end
        end
      end

      let(:implementation) do
        Class.new(base) do
          enable_response_capture

          def initialize(id)
            @id = id
          end
        end
      end

      it "makes `response_capture_enable` -> true for instances" do
        expect(subject.response_capture_enabled).to be(true)
      end
    end
  end

  describe "#capture_transformer" do
    let(:implementation) do
      Class.new(Alchemrest::Request) do
        def initialize(id)
          @id = id
        end
      end
    end

    it "defaults to a pipeline with 2 steps" do
      expect(subject.capture_transformer).to be_a(Alchemrest::Response::Pipeline)
      expect(subject.capture_transformer.steps)
        .to contain_exactly(
          Alchemrest::Response::Pipeline::ExtractPayload.new(nil, true),
          a_kind_of(Alchemrest::Response::Pipeline::Sanitize),
        )
    end
  end

  describe ".disable_response_capture" do
    context "when not used" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          def initialize(id)
            @id = id
          end
        end
      end

      it "keeps `response_capture_enable` -> true" do
        expect(subject.response_capture_enabled).to be(true)
      end
    end

    context "when used" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          disable_response_capture

          def initialize(id)
            @id = id
          end
        end
      end

      it "makes `response_capture_enable` -> false for instances" do
        expect(subject.response_capture_enabled).to be(false)
      end
    end
  end

  describe "#default_headers" do
    let(:implementation) do
      Class.new(Alchemrest::Request) do
        def initialize(id)
          @id = id
        end
      end
    end

    it "returns a Hash with the User-Agent" do
      expect(subject.default_headers).to eql("User-Agent" => "Alchemrest/#{Alchemrest::VERSION}")
    end
  end

  describe "#headers" do
    let(:implementation) do
      Class.new(Alchemrest::Request) do
        def initialize(id)
          @id = id
        end
      end
    end

    it "returns an empty Hash" do
      expect(subject.headers).to eql({})
    end
  end

  describe "#http_method" do
    let(:implementation) { Class.new(described_class) }
    subject { implementation.new }

    it 'returns a non implemented error' do
      expect { subject.http_method }.to raise_error(NotImplementedError, 'This is an abstract base method. Implement in your subclass.')
    end
  end

  describe "#path" do
    let(:implementation) { Class.new(described_class) }
    subject { implementation.new }

    it 'returns a non implemented error' do
      expect { subject.path }.to raise_error(NotImplementedError, 'This is an abstract base method. Implement in your subclass.')
    end
  end

  describe "#identifier" do
    context "when the request does not override the identifier method" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          enable_response_capture

          def initialize(id)
            @id = id
          end

          def path
            "/v1/users#{@id}"
          end

          def http_method
            'get'
          end
        end
      end
      subject { implementation.new(1) }

      it 'returns the default method + endpoint value' do
        expect(subject.identifier).to eq("#{subject.http_method.upcase} #{subject.path}")
      end
    end

    context "when the request overrides the identifier method" do
      let(:implementation) do
        Class.new(Alchemrest::Request) do
          enable_response_capture

          def initialize(id)
            @id = id
          end

          def path
            "/v1/users#{@id}"
          end

          def http_method
            'get'
          end

          def identifier
            'This is a custom identifier'
          end
        end
      end

      subject { implementation.new(1) }

      it 'returns the custom identifier' do
        expect(subject.identifier).to eq('This is a custom identifier')
      end
    end
  end
end
