# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::ResponseCapturedHandler do
  let(:request) { request_implementation.new }
  let(:status) { 200 }
  let(:success) { true }
  let(:body) do
    {
      'name' => 'Betterbot',
      'age' => 20,
      'ssn' => '123-45-6789',
    }
  end
  let(:raw_response) do
    instance_double(
      Faraday::Response,
      status:,
      success?: success,
      body:,
    )
  end
  let(:response) { Alchemrest::Response.new(raw_response) }

  subject { described_class.new(request:, response:) }

  describe "#call" do
    context "when the request has response capture enabled" do
      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          enable_response_capture

          endpoint :get, '/api/v1/users/'

          def capture_transformer
            ->(response) do
              Alchemrest::Result::Ok(response.body['name'])
            end
          end
        end
      end

      it "captures the response data" do
        expect { subject.call }.to change { captured_responses.count }.from(0).to(1)
        expect(captured_responses.sole).to eq({ data: "Betterbot", identifier: "GET /api/v1/users/", error: nil })
      end

      context 'and there is no custom capture method defined in the alchemrest config' do
        before do
          allow(Alchemrest).to receive(:on_response_captured).and_return(nil)
        end

        it "calls the default capture method which logs" do
          expect(Alchemrest.logger).to receive(:info)
            .with("Captured Alchemrest response for 'GET /api/v1/users/': 'Betterbot'")
            .and_call_original

          subject.call
        end

        context "and the capture transformer returns an error" do
          let(:request_implementation) do
            Class.new(Alchemrest::Request) do
              enable_response_capture
              endpoint :get, '/api/v1/users/'

              def capture_transformer
                ->(_response) do
                  Alchemrest::Result::Error('Error')
                end
              end
            end
          end

          it "calls the default capture method which logs" do
            expect(Alchemrest.logger).to receive(:error)
              .with("Failed to capture Alchemrest response for 'GET /api/v1/users/': 'Error'")
              .and_call_original

            subject.call
          end
        end
      end
    end

    context "when the request does not have response capture enabled" do
      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          disable_response_capture

          endpoint :get, '/api/v1/users/'
        end
      end

      it "does not capture the response" do
        expect { subject.call }.not_to change { captured_responses.count }.from(0)
      end
    end

    context "when the capture transformer returns an error" do
      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          enable_response_capture
          endpoint :get, '/api/v1/users/'

          def capture_transformer
            ->(_response) do
              Alchemrest::Result::Error('Error')
            end
          end
        end
      end

      it "captures the error" do
        expect { subject.call }.to change { captured_responses.count }.from(0).to(1)

        expect(captured_responses.sole).to eq(
          {
            error: Alchemrest::Error.new('Error'),
            identifier: 'GET /api/v1/users/',
            data: nil,
          },
        )
      end
    end

    context "when we have a custom capture method using the legacy method signature" do
      let(:legacy_captured_responses) { [] }
      let(:legacy_capture_method) do
        ->(data, response, request) do
          legacy_captured_responses << { data:, response:, request: }
        end
      end

      let(:request_implementation) do
        Class.new(Alchemrest::Request) do
          enable_response_capture

          endpoint :get, '/api/v1/users/'

          def capture_transformer
            ->(_response) do
              Alchemrest::Result::Ok('captured')
            end
          end
        end
      end

      before do
        allow(Alchemrest).to receive(:on_response_captured).and_return(legacy_capture_method)
        allow(Alchemrest.deprecator).to receive(:warn).and_return(nil)
      end

      it "calls the custom capture method passing in the expected params" do
        expect(Alchemrest.deprecator).to receive(:warn)
          .with(described_class::LEGACY_ON_RESPONSE_CAPTURED_METHOD_DEFINITION_MESSAGE)

        expect { subject.call }.to change { legacy_captured_responses.count }.from(0).to(1)
        expect(legacy_captured_responses.sole).to eq({ data: "captured", response:, request: })
      end

      context "and there is an error" do
        let(:request_implementation) do
          Class.new(Alchemrest::Request) do
            enable_response_capture
            endpoint :get, '/api/v1/users/'

            def capture_transformer
              ->(_response) do
                Alchemrest::Result::Error('Error')
              end
            end
          end
        end

        it "calls the custom capture method passing in the expected params" do
          expect { subject.call }.to change { legacy_captured_responses.count }.from(0).to(1)
          expect(legacy_captured_responses.sole)
            .to eq(
              data: "Error transforming captured response data: Error", response:,
              request:
            )
        end
      end
    end
  end
end
