# Advanced Pattern Matching

The goal of this documentation is to give you an in-depth understanding of how pattern matching works in AlchemREST and help you set up pattern matching to handle complex error scenarios.

Note you don't need to read this to get started using pattern matching for error handling in AlchemREST. If you're just getting started, we'd recommend you read [Error Handling Patterns](./error_handling_patterns.md), which provides enough of an overview of pattern matching as it applies to AlchemREST to get you started.

This page is for folks who want to understand how pattern matching in AlchemREST works, or who have complex error handling needs where they can't quite get pattern matching working the way they want.

As pre-reading, we recommend you first read the following general overview of Ruby's pattern matching syntax

* [Ruby's docs on pattern matching](https://docs.ruby-lang.org/en/3.0/syntax/pattern_matching_rdoc.html)
* [The Odin Projects pattern matching guide](https://www.theodinproject.com/lessons/ruby-pattern-matching)

We will use terms from both of these sources in the documentation below.

## Built in pattern matching

To support robust pattern matching we implement `deconstruct` and `deconstruct_keys` methods on `Alchemrest::Result` and `Alchemrest::ResponseError`. (See [Matching non-primitive objects](https://docs.ruby-lang.org/en/3.0/syntax/pattern_matching_rdoc.html#label-Matching+non-primitive+objects-3A+deconstruct+and+deconstruct_keys) from the Ruby docs for an explanation of these methods).

Let's take a look at those implementations to understand how they work

### Pattern Matching on `Alchemrest::Result`

First, our `Alchemrest::Result` classes

```ruby
class Alchemrest::Result::Error
  # ...
   def deconstruct
     [error]
   end

  def deconstruct_keys(_keys)
    { error: error }
  end
end

class Alchemrest::Result::Ok
  # ...
   def deconstruct
     [value]
   end

  def deconstruct_keys(_keys)
    { value: value }
  end
end
```

You can see both of these are very simple implementations. By itself, this allows us to write pattern matching statements like this

```ruby
value = case result
          in Alchemrest::Result::Ok(value)
            value
          in Alchemrest::Result::Error(Alchemrest::ServerError)
            :server_error
          in Alchemrest::Result::Error(Alchemrest::ClientError => e)
            e.response.data
          else
            result.unwrap_or_rescue { nil }
        end
```

Let's walk through what's happening here for each pattern

#### `in Alchemrest::Result::Ok(value)`

Ruby performs an "Object Pattern Match" on result invoking `Alchemresult::Result::Ok === result`. If this returns true, then Ruby invokes `result.deconstruct` to transform the `result` into the array `[a]` where `a` is the value wrapped by the result. It performs an "Array Pattern Match" on that array, and then binds the first and only element of that array to the variable `value`.

#### `in Alchemrest::Result::Error(Alchemrest::ServerError)`

If we fall through to the second pattern, because `Alchemrest::Result::Ok !== result`, then Ruby starts out with another "Object Pattern Match", invoking `Alchemresult::Result::Error === result`. If this returns true, then Ruby invokes `result.deconstruct` to transform the `result` into the array `[error]` where `error` is an instance of `Alchemrest::Error` wrapped by the result. It performs an "Array Pattern Match" on that array, which results in an "Object Pattern Match" that invokes `Alchemrest::ServerError === error`

#### `in Alchemrest::Result::Error(Alchemrest::ClientError => e)`

If we fall through to the third pattern, because `Alchemrest::ServerError !== error`, then we start out much the same way, with an "Object Pattern Match", followed by `result.deconstruct`, followed by an "Object Pattern Match" that invokes `Alchemrest::ClientError === error`. However, in this case we finish off with a "As Pattern Match" to assign the first element of the `[error]` array to the variable `e` (if `Alchemrest::ClientError === error`)

Finally, if we fall through all the patterns, we default to an `unwrap_or_rescue` which gives us good alerting and visibility that none of our expectations were met

You can see how even these fairly simple `deconstruct` implementations already unlock some really flexible and robust pattern matching expressions. Let's take a quick look at what a similar expression that uses `deconstruct_keys` might look like

```ruby
value = case result
          in Alchemrest::Result::Ok(value:)
            value
          in Alchemrest::Result::Error(error: Alchemrest::ServerError)
            :server_error
          in Alchemrest::Result::Error(error: Alchemrest::ClientError => e)
            e.response.data
          else
            result.unwrap_or_rescue { nil }
        end
```

You can see that this is very similar, and in many ways, somewhat redundant. As a result, we generally don't recommend using Hash based pattern matching when your pattern expressions only look at the `result` object and its "deconstructed" values. We've only implemented the `deconstruct_keys` methods here for completeness, and don't believe they serve much real value.

### Pattern matching on `Alchemrest::ResponseError`

Now let's go a step deeper and look at the implementation of these methods on `Alchemrest::ResponseError`

```ruby
class Alchemrest::ResponseError
  def deconstruct
    [response.status, response.error_details]
  end

  def deconstruct_keys(_keys)
    { status: response.status, error: response.error_details }
  end
end
```

In this case we have something slightly more complicated. Here `response` refers to the instance of `Alchemrest::Response` that errored out. `response.status` is the http code, and `response.error_details` is a method that extracts relevant information from the error (By default this is just the string "Error with HTTP status: #{status}", but we encourage implementers to override it as covered in [Error Handling Patterns](./error_handling_patterns.md#setup-our-client-to-extract-the-errors)).

Let's look at what this enables

```ruby
status = case result
           in Alchemrest::Result::Ok
             :success
           in Alchemrest::Result::Error({ status: 422, error: { code: "001" }}`)
             :locked
           else
            result.unwrap_or_rescue { nil }
         end
```

Now you'll see how we can actually drill down into information from the response in our patterns. Let's walk through things again

#### `in Alchemrest::Result::Ok`

A simple "Object Pattern Match" which just invokes `Alchemrest::Result::Ok === result`

#### `in Alchemrest::Result::Error({status: 422, error: { code: "001" }})`

If we fall through to this pattern, then we do an "Object Pattern Match" invoking `Alchemrest::Result::Error === result`. If that is true then we call `result.deconstruct` which returns the array `[error]`. Then Ruby performs an "Array Pattern Match" which attempts to compare the `error` object to the hash `{status: 422, error: { code: "001" }}`. This results in a "Hash Pattern Match", which invokes `error.deconstruct_keys` to return `{ status: response.status, error: response.error_details }`. These 2 hashes are compared by Ruby using `422 === response.status` and `"001" === response.error_details[:code]` If both those statements are true, then we have a match and Ruby executes the body. Note if we have a response with a different error code, like "002", then we'll fall through and get a `NoMatchingPatternError`

Now you can see how we're able to get this nice nested syntax through the nested patterns supported by `deconstruct` and `deconstruct_keys`

## How to customize pattern matching

Now that you understand how pattern matching in AlchemREST actually works, let's talk about tools for customization. The main way AlchemREST supports customization is via a custom `Alchemrest::Response` class that overrides `error_details`. In the simplest implementation, you can just have that method look something like this, assuming the API you're integrating with just has a top level errors key

```ruby
def error_details
  data["errors"]
end
```

Now you have access to the raw structure returned by the API for pattern matching. Let's imagine the `errors` is just a simple array of error strings. Now you can do something like

`in Alchemrest::Result::Error({status: 422, error: ["Username already exists"])`

This will match any response body that has a single error "Username already exists".

But what if you find yourself writing a lot of code that checks for this, and you don't love typing out "Username already exists" every time, especially since you keep making the type "exists" => "exits". Well we can modify `error_details` to give us back a different structure

```ruby
def error_details
  errors = {}
  errors[:username_taken] = data["errors"].include("Username already exists")
  errors
end
```

Now we can write this pattern

`in Alchemrest::Result::Error({status: 422, error: { username_taken: true }})`

You can basically define your own API for pattern matching this way.

## Exploring alternative patterns

In the sections above, we looked at the patterns that we generally recommend for working with `Alchemrest::Result` and `Alchemrest::Error` objects. This generally boils down to the following rules

* Use "Object Pattern Matching" on `Alchemrest::Result` to distinguish success cases from error cases (eg `in Alchemrest::Result::Ok`)
* Use "Array Pattern Matching" on `Alchemrest::Result::Ok` to extract the value from the result (eg `in Alchemrest::Result::Ok(value)`)
* Use "Hash Pattern Matching" on the error wrapped by `Alchemrest::Result::Error` (eg `in Alchemrest::Result::Error(status: 422)` to match on error details.)

In this second we're going to explore a handful of other valid patterns, and walk through how they work. The goal here is to help build your mental model for understanding how patterns work in general, as well as giving you tools to handle uncommon scenarios. However, we recommend sticking to the above rules wherever possible because we think they create highly legible and easy to understand code with minimal verbosity. Note, this is not an exhaustive exploration of all alternative patterns, since ruby's pattern matching is so flexible that it would be difficult to categorize. We hope it's a sort of representative sample that gives you a sense of how pattern matching and Alchemrest work in general.

### `in Alchemrest::Result::Ok[value]`

This pattern is equivalent to `in Alchemrest::Result::Ok(value)`. We just wanted to highlight that parenthesis and brackets can be used interchangeably for both "Array Pattern Matching" and "Hash Pattern Matching" nested inside an "Object Pattern Match". So this is also equivalent `in Alchemrest::Result::Ok[value: value]`

### `in Alchemrest::Result::Ok(Bank::Api::User => user)`

This pattern does a nested "Object Pattern Match" on the value of an ok result, calling `Bank::Api::User === user` to confirm it is in fact a `Bank::Api::User`. This might be useful if you have an endpoint that returns a polymorphic type somewhere in the data structure, and you've transformed your result to access that type directly.

### `in { error: { status: 422 } }`

This pattern skips the typical "Object Pattern Match" and goes straight to a "Hash Pattern Match". Since ``Alchemrest::Result#deconstruct_keys` returns a hash like `{error: error}`, the output hash matches, and then Ruby does a nested "Hash Pattern Match" calling:

`Alchemrest::ResponseError#deconstruct_keys`

This is less verbose, but hides the fact that `Alchemrest` is involved for those that aren't familiar with it.
