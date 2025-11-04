# frozen_string_literal: true

module Alchemrest
  class Data
    # This class has two purposes. First it provides the DSL that allows developers to mark fields on a
    # Alchemrest::Data class as safe or omitted. Second, it walks the entire object graph of nested
    # objects to build up full path definitions for all the safe an omitted fields defined on child
    # objects as well.
    #
    # @example Using `Alchemrest::Data::CaptureConfiguration` to delete define some safe and omitted fields
    # CaptureConfiguration.new(BankApi::Data::User) do
    #  safe :name
    #  omitted :age
    # end
    #
    # The attribute `path_to_payload` allows us to deal with situations where the domain data defined
    # by the host class is nested inside a larger payload. For example `{ data: { user: { user data } } }`
    class CaptureConfiguration
      attr_reader :safe_keys, :omitted_keys, :path_to_payload

      def initialize(host_class:, path_to_payload: nil, omitted_keys: [], safe_keys: [], &block)
        raise ArgumentError, "Must be a sub class of Alchemrest::Data" unless host_class < Alchemrest::Data

        @host = host_class
        @path_to_payload = path_to_payload
        @safe_keys = safe_keys
        @omitted_keys = omitted_keys
        instance_eval(&block) unless block.nil?
      end

      def with_path_to_payload(path_to_payload)
        self.class.new(
          host_class: @host,
          path_to_payload:,
          safe_keys:,
          omitted_keys:,
        )
      end

      def safe_paths
        paths = @safe_keys.dup

        paths.concat(get_child_paths(:safe_paths))
        paths.map { |path| prefix_with_path_to_payload_nodes(path) }
      end

      def omitted_paths
        paths = @omitted_keys.dup

        paths.concat(get_child_paths(:omitted_paths))
        paths.map { |path| prefix_with_path_to_payload_nodes(path) }
      end

      def safe(*keys)
        @safe_keys = keys
      end

      def omitted(*keys)
        @omitted_keys = keys
      end

      private

      def get_child_paths(type)
        paths = []
        @host.graph.sub_graphs.each do |key, child|
          paths << { key => child.type.capture_configuration.public_send(type) }
        end
        paths
      end

      def prefix_with_path_to_payload_nodes(path)
        Array(path_to_payload).reverse.reduce(path) { |child, key| { key => child } }
      end
    end
  end
end
