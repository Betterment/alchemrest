# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::Response::Pipeline, squad: :employee_wellness do
  let(:steps) { [] }
  subject { described_class.new(*steps) }

  describe "#call" do
    let(:response) do
      Alchemrest::Response.new(
        instance_double(Faraday::Response, body:, env:, success?: true, status: 200),
      )
    end
    let(:body) { { "data" => { "user" => { "name" => "John" } } } }
    let(:env) do
      Faraday::Env.new.tap do |e|
        e.method = :get
        e.url = URI("https://example.com")
      end
    end

    context "a simple pipeline" do
      let(:steps) do
        [
          Alchemrest::Response::Pipeline::WasSuccessful.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new(%i(data user)),
        ]
      end

      it "invokes the steps and returns the final result as an Alchemrest::Result::Ok" do
        result = subject.call(response)
        expect(result).to be_a(Alchemrest::Result::Ok)
        expect(result.unwrap_or_raise!).to eq({ "name" => "John" })
      end
    end

    context "a pipeline which returns a Final value" do
      let(:final_transform) do
        Class.new(Alchemrest::Response::Pipeline::Transform) do
          def call(_input)
            final("we done")
          end
        end
      end

      let(:steps) do
        [
          final_transform.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new(%i(data user)),
        ]
      end

      it "short circuits execution and returns the final value" do
        result = subject.call(response)
        expect(result).to be_a(Alchemrest::Result::Ok)
        expect(result.unwrap_or_raise!).to eq("we done")
      end
    end

    context "a pipeline which has a step that returns one of our Alchemrest.rescuable_errors" do
      let(:rescuable_error_transform) do
        Class.new(Alchemrest::Response::Pipeline::Transform) do
          def call(_input)
            failure(Alchemrest::ResponsePipelineError.new("Something went wrong"))
          end
        end
      end

      let(:steps) do
        [
          rescuable_error_transform.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new(%i(data user)),
        ]
      end

      it "returns an Alchemrest::Result::Error" do
        result = subject.call(response)
        expect(result).to be_a(Alchemrest::Result::Error)
        expect { result.unwrap_or_raise! }.to raise_error(Alchemrest::ResponsePipelineError)
      end
    end

    context "a pipeline which as a step that returns a Morpher::Transform::Error" do
      let(:user_data_class) do
        Class.new(Alchemrest::Data) do
          schema do |s|
            {
              required: {
                name: s.string,
                age: s.integer,
              },
            }
          end
        end
      end

      let(:steps) do
        [
          Alchemrest::Response::Pipeline::WasSuccessful.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new(%i(data user)),
          user_data_class::TRANSFORM,
        ]
      end

      it "returns an Alchemrest::Result::Error wrapping a Alchemrest::MorperTransformError" do
        result = subject.call(response)
        expect(result).to be_a(Alchemrest::Result::Error)
        expect { result.unwrap_or_raise! }.to raise_error(Alchemrest::MorpherTransformError)
      end
    end

    context "a pipeline that returns some other kind of error" do
      let(:not_rescuable_error_transform) do
        Class.new(Alchemrest::Response::Pipeline::Transform) do
          def call(_input)
            failure(ArgumentError.new("Something went wrong"))
          end
        end
      end

      let(:steps) do
        [
          not_rescuable_error_transform.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new(%i(data user)),
        ]
      end

      it "raises" do
        expect { subject.call(response) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#append" do
    it "adds a new item to the pipeline" do
      pipeline = subject.append(Alchemrest::Response::Pipeline::ExtractPayload.new)
      expect(pipeline.steps).to eq([Alchemrest::Response::Pipeline::ExtractPayload.new])
    end

    context 'with a existing steps' do
      let(:steps) { Alchemrest::Response::Pipeline::ExtractPayload.new }

      it "adds it to a new pipeline" do
        pipeline = subject.append(Alchemrest::Response::Pipeline::Sanitize.new)
        expect(pipeline.steps)
          .to eq(
            [
              Alchemrest::Response::Pipeline::ExtractPayload.new,
              Alchemrest::Response::Pipeline::Sanitize.new,
            ],
          )
      end
    end
  end

  describe "#replace_with" do
    context "when the pipeline has the class being replaced" do
      let(:steps) { [Alchemrest::Response::Pipeline::Sanitize.new] }

      it "swaps out the equivalent step" do
        pipeline = subject.replace_with(
          Alchemrest::Response::Pipeline::Sanitize,
          Alchemrest::Response::Pipeline::Sanitize.new(safe: %w(data ssn)),
        )

        expect(subject.steps).to eq(steps)
        expect(pipeline.steps).to eq([Alchemrest::Response::Pipeline::Sanitize.new(safe: %w(data ssn))])
      end
    end

    context "when the pipeline does have the class being replaced" do
      let(:steps) do
        [
          Alchemrest::Response::Pipeline::WasSuccessful.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new,
        ]
      end

      it "raises" do
        expect {
          subject.replace_with(
            Alchemrest::Response::Pipeline::Sanitize,
            Alchemrest::Response::Pipeline::Sanitize.new(safe: Alchemrest::HashPath.new(%w(data ssn))),
          )
        }.to raise_error ArgumentError, "Step Alchemrest::Response::Pipeline::Sanitize not found"
      end
    end
  end

  describe "#insert_after" do
    context "when the pipeline has the class being replaced" do
      let(:steps) do
        [
          Alchemrest::Response::Pipeline::WasSuccessful.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new,
          Alchemrest::Response::Pipeline::Omit.new(Alchemrest::HashPath.new(['request_id'])),
        ]
      end

      it "adds the step" do
        pipeline = subject.insert_after(
          Alchemrest::Response::Pipeline::ExtractPayload,
          Alchemrest::Response::Pipeline::Sanitize.new(safe: Alchemrest::HashPath.new(%w(data ssn))),
        )

        expect(pipeline.steps)
          .to eq(
            [
              Alchemrest::Response::Pipeline::WasSuccessful.new,
              Alchemrest::Response::Pipeline::ExtractPayload.new,
              Alchemrest::Response::Pipeline::Sanitize.new(safe: Alchemrest::HashPath.new(%w(data ssn))),
              Alchemrest::Response::Pipeline::Omit.new(Alchemrest::HashPath.new(['request_id'])),
            ],
          )
      end
    end

    context "when the pipeline does not have the class being replaced" do
      let(:steps) do
        [
          Alchemrest::Response::Pipeline::WasSuccessful.new,
          Alchemrest::Response::Pipeline::ExtractPayload.new,
        ]
      end

      it "raises" do
        expect {
          subject.insert_after(
            Alchemrest::Response::Pipeline::Sanitize,
            Alchemrest::Response::Pipeline::Sanitize.new(safe: %w(data ssn)),
          )
        }.to raise_error ArgumentError, "Step Alchemrest::Response::Pipeline::Sanitize not found"
      end
    end
  end
end
