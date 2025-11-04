# Custom Transformations with Morpher

As covered in [Working with Data](./working_with_data.md), AlchemREST converts JSON data into our domain data classes using Morpher. We ship with a series of prebuilt Morpher transforms and related helpers found in [Alchemrest::Data::Transforms](../lib/alchemrest/data/transforms.rb). In this documentation, we cover what to do if you need to create a custom transformation that's not included in these helpers. You can either define and use this helper directly in your application, or if you think it has broad use, you can open a pull request and add it as one of the built-in transformations

Before reading this documentation you should probably make sure you have already reviewed [Working with Data](./working_with_data.md) and [Error Handling Patterns](./error_handling_patterns.md) to ensure you are well grounded in basic AlchemREST patterns

## When should I create a transformation?

In general, you probably won't need to create a custom transformation in many circumstances. As covered in [Working with Data](./working_with_data.md), AlchemREST makes it easy to decorate your data classes with domain specific methods. This serves as a great way to take the raw data from the API and mold it into something that better fits your needs. Because data classes are just plain ruby objects, you can also create reusable concerns and modules to mixin to classes and handle some of the basic data manipulation logic.

In general, you really only need to reach for a full-blown transformation in situations where you are need high confidence that the data you get from a third party API meets your expectations, and when it doesn't meet your expectations you want to make sure that your downstream code can handle it safely using standard AlchemREST error handling strategies. We'll show you an example of something like this as you continue reading this documentation.

## A Simple Transformation

At its heart, a transformation is simply a class that inherits from `Morpher::Transform` and implements a call method that takes the pre-transformation value in as an input and gives the transformed value wrapped in a success/failure wrapper similar to `Alchemrest::Result`. Let's take a look at a simple example

Let's imagine that the Bank.com API adds a new API where you can get the current interest rate for their savings accounts. To return that interest rate as a string like "4.25%", you want to convert that to a ruby `BigDecimal`. Here's a naive transform

```ruby
class PercentString < Morpher::Transform
  def call(input)
    success(input.chop.to_d)
  end
end
```

This relies on the fact that `"4.00%".chop.to_d` gives you `BigDecimal("4.0")`. Of course there are significant flaws with this transformation, because what if we get a non-percent string like "lalala"? Then `to_d` returns `0.0`.

So we need to modify this transformation to strictly validate our data first.

```ruby
class PercentString < Morpher::Transform
  def call(input)
    unless input[-1] == "%"
      return failure(error(message: "Expected a string of the form '<num>%", input: input))
    end

    success(BigDecimal.new(input.chop))
  rescue ArgumentError
    raise unless e.message.start_with? "invalid value for BigDecimal()"

    failure(
      error(
        message: "Expected: #{input} to be a decimal",
        input: input,
       ),
    )
  end
end
```

This looks a little better. Now if we get a non-numeric string, or an empty string, `BigDecimal.new` will raise, and our transformation will be marked as a failure, resulting in a `Alchemrest::MorpherTransformError`. But what if we get bogus percent values, like 110% or -15%. Well to cover that, we need to go even further in our validations.

```ruby
class PercentString < Morpher::Transform
  def call(input)
    unless input[-1] == "%"
      return failure(error(message: "Expected a string of the form '<num>%", input: input))
    end

    decimal = BigDecimal.new(input.chop)
    if decimal > 100
      failure(error(message: "#{input} is greater than 100%", input: input))
    elsif decimal < 0
      failure(error(message: "#{input} is less than 0%", input: input))
    else
      success(decimal)
    end
  rescue ArgumentError
    raise unless e.message.start_with? "invalid value for BigDecimal()"

    failure(
      error(
        message: "Expected: #{input} to be a decimal",
        input: input,
       ),
    )
  end
end
```

With these changes, our downstream code can now safely make the assumption that the interest rate field will always be a number between 0 and 100.

This gives us the opportunity to discuss the key principles of transforms

* Transforms should strictly validate their data, and fail if the data is not in the expected format. The goal is to make it so any code that consumes the value after transformation can act naively, and avoid worrying about failure cases.
* Transforms should not raise, and instead should use the `failure` and `error` methods to gracefully capture errors that can be handled via typical AlchemREST processes.

## Using the Transformation

To use the transformation, we can new it up inside of our schema definition. So let's imagine the rate is part of a `/products` endpoint, for which we've defined a new `Product` class like below

```ruby
class Product < Alchemrest::Data
  schema do |s|
    {
      required: {
        name: s.string,
        interest_rate: PositiveInterestString.new,
      }
    }
  end
end
```

You see how we just new up an instance of our transformation and put that where we would usually call one of the transformation helper methods

## Transformations with constructor arguments

Sometimes you want transformations that can take in arguments the time you set them up. Let's return to our product data model and imagine that Bank.com has added another value to that endpoint named `partner_revenue_rate`. This is another string percentage value that represents the percent of the balance in an account that's given to the partner as part of the revenue sharing agreement we've signed with Bank.com.

Furthermore, we've gotten guidance from Bank.com that the interest rate will always have 2 decimal places, and the revenue rate will always have 4. Our downstream code has precision math that relies on these facts, so we want to make sure an API response never drifts from this understanding. In that case, we might want to do something like this.

```ruby
class Product < Alchemrest::Data
  schema do |s|
    {
      required: {
        name: s.string,
        interest_rate: PositiveInterestString.new(2),
        partner_revenue_rate: PositiveInterestString.new(4),
      }
    }
  end
end
```

To make our `PositiveInterestString` transformation support that, we can do the following

```ruby
class PositiveInterestString < Morpher::Transform
  attr_reader :decimal_places

  def initialize(decimal_places)
    @decimal_places = decimal_places
  end

  def call(input)
    unless input[-1] == "%"
      return failure(error(message: "Expected a string of the form '<num>%", input: input))
    end

    decimal = BigDecimal.new(input)
    if input.split(".")[1].count != decimal_places
      failure(error(message: "Expected #{input} to have #{decimal_places} decimal_places", input: input))
    elsif decimal < 0
      failure(error(message: "#{input} is less than 0%", input: input))
    else
      success(decimal)
    end
  rescue ArgumentError
    failure(
      error(
        message: "Expected: #{input} to be a decimal",
        input: input,
      ),
    )
  end
end
```

Now the transformation accepts an argument, which we can use in the call method as part of our validations. One thing you may note is that we've chosen to use positional arguments rather than kwargs. This is one current limitation of Morpher, that transformations cannot accept kwargs. We are evaluating how to fix that in the future though.

## A note on built in transformations, Concord and Anima

If you look at the source code for the built-in AlchemREST transformation, you'll see a number of references to `Concord` and `Anima`. These are from the gems [Concord](https://github.com/mbj/concord) and [Anima](https://github.com/mbj/anima) respectively. A full explanation of these gems is beyond the scope of this document, but a high level explanation is they provide tooling to simplify the process of defining instance attributes that are defined by initializer arguments. They are not necessary to create custom transformations, and if you're not interested in using them, you can just use typical object initialization patterns, like we've outlined in our `PercentString` example.
