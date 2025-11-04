# frozen_string_literal: true

module Alchemrest
  class Data
    # A simple data structure to hold a graph of all the objects in a schema.
    class Graph
      include Anima.new(:type, :sub_graphs, :fields)

      def initialize(type:, sub_graphs: nil, fields: nil)
        unless type < Data
          raise ArgumentError, "Graph types must be branching Alchemrest::Data class"
        end
        unless sub_graphs.nil? || sub_graph_hash_has_correct_types?(sub_graphs:)
          raise ArgumentError, "sub_graphs must be a hash of graphs"
        end
        unless fields.nil? || fields_hash_has_correct_types?(fields:)
          raise ArgumentError, "fields must be a hash of fields"
        end

        @type = type
        @fields = fields
        @sub_graphs = sub_graphs
      end

      def children
        sub_graphs
      end

      private

      def sub_graph_hash_has_correct_types?(sub_graphs:)
        sub_graphs.instance_of?(Hash) && sub_graphs.values.all? { |graph| graph.instance_of?(Graph) }
      end

      def fields_hash_has_correct_types?(fields:)
        fields.instance_of?(Hash) && fields.values.all? { |graph| graph.instance_of?(Field) }
      end
    end
  end
end
