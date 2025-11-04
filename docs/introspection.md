# Introspection

One interesting side effect of Alchemrest's design is that you naturally build up a fairly rich object graph of the API response data you work with. Writing and `Alchemerst::Data` class forces you to define the shape of the API responses you care about, along with details about the types and values of each field.

Alchemrest provides some mechanisms to introspect this information. Internally we actually use this same introspection interface to create a [Tapioca](https://github.com/Shopify/tapioca) compiler that generates [Sorbet](https://github.com/sorbet/sorbet) types for `Alchemrest::Data` classes. But you can use it yourself to generate documentation, automate creating things like database tables to store API responses, etc. In this document we'll cover the basic usage of the introspection features Alchemrest provides

## Alchemrest::Data::Graph

The main entrypoint into the introspection interface is the `Alchemrest::Data::Graph` class. Each `Alchemrest::Data` implementation you create has its own `Graph` which you can access via `Alchemrest::Data.graph`. The graph exposes 2 methods `Graph#fields` and `Graph#sub_graphs`

`Graph#fields` provides a hash with symbol keys corresponding to each field defined by your schema, and values that are of type `Alchemrest::Data::Field`

`Graph#sub_graphs` provides a hash with symbol keys corresponding to each field defined by you schema which returns another `Alchemrest::Data` implementation. (*Note: At this time we don't actually support detecting subgraphs for polymorphic types, so they will not show up as part of this hash*). The values will by the `Alchemrest::Data::Graph` for each of those nested object types

## Alchemerst::Data::Field

The `Alchemrest::Data::Field` class exposes the following methods

* `name` - Simply returns the value of the key from the schema definition
* `transform` - Returns the underlying `Morpher::Transform` that the value is piped through to process API responses
* `required` - Indicates if the field is required. Note this will be true if schema includes the field in the `required` hash, even if the transform is a `maybe` transform that allows for nilability
* `output_type` - Returns an `Alchemrest::Transforms::OutputType` object representing the type that is returned by the `transform`. We'll cover this in more detail in the subsequent section
* `constraints` - An array of the `Alchemrest::Transform::Constraint` objects that are part of the `transform`

## Alchemerst::Transforms::OutputType

The `Alchemrest::Transforms::OutputType` class serves to provide information on what the final type of a field will be after applying the relevant transform. It exposes the following methods

* `sorbet_type` - We actually use `sorbet` under the hood as a means to represent types, since it offers a standard, convenient way, to express concepts like "An array of X", or "X but also nil" or "a Boolean". So what `sorbet_type` returns is a "sorbet compatible" type definition, meaning either the raw underlying class (ie `String`, `Symbol`, `Integer`, `BankApi::Data::User`), a Sorbet wrapper (ie `T::Array[String]`, `T.nilable(String)`, `T.any(Float, Integer)`), or a Sorbet alias (ie `T::Boolean`).

When this returns a raw class, it's relatively easy to introspect things, but when it returns one of the Sorbet types, that's less straightforward. While Sorbet does expose its own introspection interface, it is not documented, so you may want to be careful in reaching into some of those methods.

* `graph` - This returns an `Alchemrest::Data::Graph` if the underlying type has one. It helps deal with situations where the actual type is `T::Array[Alchemerst::Data]` or `T.nilable(Alchemrest::Data)` so extracting the graph from the type might be difficult

## Alchemrest::Transforms::Constraint

The `Alchemrest::Transforms::Constraint` class is covered in more detail in [Chainable Transforms](./chainable_transforms.md), but for the purposes of introspection, the most interesting method is `Constraint#description`. This gives a human readable description of the constraint, which may be useful for outputting documentation

## Putting it all together

To understand how to use all these classes in practice, let's look at a small example from our [Examples](../examples/) folder. Here's a class that can use this introspection API to print out documentation on all the `Alchemrest::Data` classes in our application

```ruby
module BankApi
  class GraphVisualization
    extend T::Sig

    sig { returns(T::Array[Alchemrest::Data::Graph]) }
    def graphs
      BankApi::Data.constants.map do |name|
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
      io.puts(graph.type.name.indent(indent))
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
```

So you can see, we get all the constants that are `Alchemrest::Data` classes, and call `.graph` on each. We feed that graph into a function that recursively prints out the graphs fields and any sub_graphs. For each field we print the type, and the description of any constraints applied to that type.
