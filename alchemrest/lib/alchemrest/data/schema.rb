# frozen_string_literal: true

module Alchemrest
  class Data
    class Schema < Alchemrest::Data::Record
      def included(host)
        super

        host.extend(ClassMethods)

        host.const_set(
          :Collection,
          Class.new(host) do
            const_set :TRANSFORM, superclass::TRANSFORM.array

            def self.capture_configuration
              superclass.capture_configuration
            end
          end,
        )

        # Store the graph as a constant for easy access from other classes
        host.const_set(:GRAPH, extract_graph(host))
      end

      private

      def extract_graph(host)
        Graph.new(
          type: host,
          sub_graphs: extract_sub_graphs,
          fields: extract_fields,
        )
      end

      def extract_sub_graphs
        required.merge(optional)
          .filter { |_k, v| v.respond_to?(:output_type) && v.output_type.graph }
          .transform_values { |v| v.output_type.graph }
      end

      def extract_fields
        required_fields = required.map { |k, v| [k, Field.new(transform: v, name: k, required: true)] }
        optional_fields = optional.map { |k, v| [k, Field.new(transform: v, name: k)] }
        (required_fields + optional_fields).to_h
      end

      module ClassMethods
        def capture_configuration
          @capture_configuration ||= CaptureConfiguration.new(host_class: self)
        end

        def response_transformer
          Alchemrest::ResponseTransformers::Morpher.new(self::TRANSFORM)
        end

        def from_hash(hash)
          transform_prelude = self::TRANSFORM.call(hash.deep_stringify_keys)
          if transform_prelude.right?
            transform_prelude.from_right
          else
            raise MorpherTransformError, transform_prelude.from_left
          end
        end

        def []
          self::Collection
        end

        def graph
          self::GRAPH
        end

        def configure_response_capture(&)
          @capture_configuration = CaptureConfiguration.new(host_class: self, &)
        end
      end
    end
  end
end
