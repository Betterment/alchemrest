# typed: true

module Alchemrest

  sig { returns(Logger) }
  def self.logger; end

end

class Alchemrest::Data::CaptureConfiguration

  sig { params(keys: Symbol).void }
  def safe(*keys); end

  sig { params(keys: Symbol).void }
  def omitted(*keys); end
end

class Alchemrest::Data
  sig { params(hash: T::Hash[T.any(Symbol, String), T.untyped]).returns(T.attached_class) }
  def self.from_hash(hash); end

  sig { returns(Alchemrest::Data::Graph) }
  def self.graph; end

  sig { returns(T.class_of(Alchemrest::Data)) }
  def self.[]; end

  sig { params(blk: T.proc.bind(Alchemrest::Data::CaptureConfiguration).void).void }
  def self.configure_response_capture(&blk); end

  sig { void }
  def self.schema; end

  sig { params(attributes: T.untyped).void }
  def initialize(**attributes); end

  sig { returns(T::Hash[T.untyped, T.untyped]) }
  def to_h; end
end

class Alchemrest::Data::Graph
  sig { returns(T::Hash[Symbol, Alchemrest::Data::Field]) }
  def fields; end

  sig { returns(T.class_of(Alchemrest::Data)) }
  def type; end

  sig { returns(T::Hash[Symbol, Alchemrest::Data::Graph]) }
  def sub_graphs; end
end

class Alchemrest::Data::Field
  sig { returns(T::Array[Alchemrest::Transforms::Constraint]) }
  def constraints; end

  sig { returns(T.nilable(Alchemrest::Transforms::OutputType)) }
  def output_type; end
end

class Alchemrest::UrlBuilder::Options
  sig { params(values: T::Hash[Symbol, T.untyped]).void }
  def query=(values); end

  sig { params(values: T::Hash[Symbol, T.untyped]).void }
  def values=(values); end

  sig { params(name: Symbol).void }
  def encode_query_with=(name); end

  sig { params(block: T.proc.params(query: T::Hash[Symbol, T.untyped]).returns(String)).void }
  def encode_query_with(&block); end
end

class Alchemrest::EndpointDefinition
end

class Alchemrest::Transforms::OutputType
  sig { returns(T.nilable(Alchemrest::Data::Graph)) }
  def graph; end

  sig { returns(T.untyped) }
  def sorbet_type; end

  sig { returns(T::Array[Alchemrest::Transforms::Constraint]) }
  def constraints; end
end

class Alchemrest::Transforms::Constraint
  sig { returns(String) }
  def description; end
end


class Alchemrest::Request
  class << self
    sig do
      params(
        http_method: Symbol,
        template: String,
        block: T.nilable(T.proc.bind(T.attached_class).params(url: Alchemrest::UrlBuilder::Options).void),
      ).void
    end
    def endpoint(http_method, template, &block); end

    sig do
      params(
        domain_type: T.class_of(Alchemrest::Data),
        path_to_payload: T::Array[T.any(Symbol, String)],
        allow_empty_response: T::Boolean
      ).void
    end
    def returns(domain_type, path_to_payload: nil, allow_empty_response: false); end

    sig { void }
    def enable_response_capture; end
  end
end

class Alchemrest::Response < SimpleDelegator
  sig { returns(Integer) }
  def status; end

  sig { returns(T.untyped) }
  def body; end

  sig { returns(T::Hash[T.untyped, T.untyped]) }
  def headers; end

  sig { returns(String) }
  def reason_phrase; end

  sig { returns(T::Boolean) }
  def success?; end
end

class Alchemrest::Response::Pipeline
end

class Alchemrest::Response::Pipeline::Transform
end

class Alchemrest::Response::Pipeline::ExtractPayload
end

class Alchemrest::Client

  sig { params(block: T.proc.params(config: Alchemrest::Client::Configuration).bind(T.attached_class).void).void }
  def self.configure(&block); end

end

class Alchemrest::CircuitBreaker; end

class Alchemrest::Client::Configuration

  sig { returns(Alchemrest::Client::Configuration::Connection) }
  def connection; end

  sig { params(service_name: String).void }
  def service_name=(service_name); end

  sig do
    params(
      value: T.any(
        T::Boolean, Alchemrest::CircuitBreaker,
        {
          disabled_when: T.nilable(T.proc.returns(T::Boolean)),
          sleep_window: Integer,
          time_window: Integer,
          error_threshold: Integer,
          volume_threshold: Integer,
        }
      )
    ).void
  end
  def use_circuit_breaker(value); end

  sig { params(value: T::Boolean).void }
  def use_kill_switch(value); end
end

class Alchemrest::Client::Configuration::Connection

  sig { params(url: String).void }
  def url=(url); end

  sig { params(block: T.proc.params(connection: Faraday::Connection).void).void }
  def customize(&block); end
end


class Alchemrest::RequestDefinition
end

class Alchemrest::RequestDefinition::Builder
  sig { params(value: T::Hash[Symbol, T.untyped]).void }
  def defaults=(value); end
end

class Alchemrest::Root
  WithParams = T.type_alias { T.proc.returns(T::Hash[Symbol, T.untyped]) }

  sig { returns(T::Hash[Symbol, Alchemrest::RequestDefinition]) }
  def self.request_definitions; end

  sig { params(client_class: T.class_of(Alchemrest::Client)).void }
  def self.use_client(client_class); end

  sig do
    params(
      name: Symbol,
      request_class: T.class_of(Alchemrest::Request),
      block: T.nilable(
        T.proc
         .params(request: Alchemrest::RequestDefinition::Builder)
         .bind(T.attached_class)
         .void,
      ),
    ).void
  end
  def self.define_request(name, request_class, &block); end

  sig { params(block: T.proc.bind(T.attached_class).params(error: Exception).void).void }
  def self.on_alchemrest_error(&block); end

  sig { params(name: Symbol, params: T::Hash[Symbol, T.untyped]).returns(Alchemrest::Request) }
  def build_request(name, params = nil); end

  sig { returns(Alchemrest::Client) }
  def client; end
end

module Alchemrest::Result::TryHelpers
  class << self
    sig do
      type_parameters(:Value)
        .params(result: Alchemrest::Result[T.type_parameter(:Value)])
        .returns(T.type_parameter(:Value))
    end
    def unwrap(result); end
  end
end

module Alchemrest::FactoryBot
end
