# frozen_string_literal: true
# typed: true

require "active_support/core_ext/string/indent"

module BankApi
  # A simple, toy example of how to interact with the introspection interface in alchemrest.
  # Outputs a tree like string showing the graph of all response objects defined in our examples
  class GraphVisualization
    extend T::Sig

    sig { returns(T::Array[Alchemrest::Data::Graph]) }
    def graphs
      BankApi::Data.constants.sort.map do |name|
        BankApi::Data.const_get(name).graph
      end
    end

    def tree_string
      io = StringIO.new
      graphs.each do |graph|
        print_graph!(graph, io)
      end
      io.string
    end

    private

    sig { params(graph: Alchemrest::Data::Graph, io: StringIO, indent: Integer).void }
    def print_graph!(graph, io, indent: 0)
      io.puts(T.must(graph.type.name).indent(indent))
      graph.fields.each do |key, field|
        output_type = field.output_type
        io.puts("- #{key} => #{output_type ? output_type.sorbet_type : 'unknown'}".indent(indent))
        field.constraints.each do |constraint|
          io.puts("* #{constraint.description}".indent(indent + 2))
        end
      end
      graph.sub_graphs.each do |key, sub_graph|
        io.puts "- #{key}"
        print_graph!(sub_graph, io, indent: 2)
      end
    end
  end
end
