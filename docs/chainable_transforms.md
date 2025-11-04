# Chainable Transforms

Chainable transforms is an interface to make it easy for developers to build a complex pipeline that validates and transforms a piece of input data. Here's an example of it in use

```ruby
module BankApi
  module Data
    class Product < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            ...
            partner_revenue_rate: s.from.string.where.matches(/^\d+(?:\.\d{1,4})?$/).to(BigDecimal).where("less than 10") { |input| input < 10 }
          },
        }
      end
    end
  end
end
```

Here you can see the basic structure of a chainable transform. More generically `s.from.<number|string>.where.<constraints>.to(<Type>).where<constraint>`. Let's break this down and look at each part individually.

## From

Chainable transforms start with a `s.from.<number|string>` call. As you might expect, this represents the input type of the data. `string` is unsurprisingly any string, while `number` can be either a `Float` or an `Integer`. The goal here is to provide easy representation for the key types in a JSON response. JSON only supports string, number, and boolean scalars, and generally we assume there's no real use cases for a `from.boolean` transformation. Note just like other kinds of transforms, you can always append `.array` on the end of the transform to work with an array of values.

Ultimately calling `from.<string|number>` does two things. It validates that the source type is whichever type you selected, and it sets up what constraint methods and transformation methods are available in the next parts of the chain, which we'll cover now

## Where

Next you can optionally make a call to `where`, which will allow you to further chain a series of "constraints" onto the transform. Constraints are methods like `matches(<pattern>)` which will make sure the input returns true for some predicate. In this case `matches` checks the input against a provided regex, and the transform only succeeds if it matches.

The methods exposed by off `where` are different depending on whether you invoked `from.string` or `from.number`, For a full list of available methods check out the classes in [this folder](../lib/alchemrest/transforms/constraint_builder/).

### Block Constraints

In addition to the built in methods provided by the constraint builder classes, you can also pass a block to where like `where("is palindrome") { |input| input.reverse == input }`. If your block returns a falsy value for a given input, for example "apple", then the chain will result in a Morpher transformation error with the description `Input apple does not meet the constraint "is palindrome"`

### Custom constraints

If you're using the same block in multiple places, you can turn it into a custom constraint. A constraint is just a class that implements `Alchemrest::Transforms::Constraint`. So for our above palindrome example, your custom constraint would look like this

```ruby
class IsPalindrome < Alchemrest::Transforms::Constraint 
  
  def description
    "is palindrome"
  end
  
  def meets_conditions?(input)
    input.reverse == input
  end
end
```

You can then use this constraint with `where(IsPalindrome.new)`. Note your custom constraint classes can take in initializer arguments, allowing you to have a single class which can vary it's behavior based on inputs. Behind the scenes all the built in methods on `where` like `where.matchs(<pattern>)` use this strategy. Here's the constraint class that backs that `matches` method

```ruby
module Alchemrest
  module Transforms
    class Constraint
      class MatchesRegex < self
        
        attr_reader :regex
        
        def initialize(regex)
          @regex = regex
        end

        def meets_conditions?(input)
          input.match?(regex)
        end

        def description
          "matches #{regex.inspect}"
        end
      end
    end
  end
end
```

## To

Whether or not you use `where` to constrain your input further, you can call `to` to transform it to another type. Alchemrest defines a number of built in transformations to move the core JSON number (`Float` and `Integer`) and string types to other common types. For example, you can write something like `s.from.string.to(Time)` to convert a string written in iso date time format a ruby to `Time` instance.

In some cases, there might be multiple ways to convert an input value to a particular type. For example `s.from.number.to(Money)` on its own is ambiguous. Is your input value cents, or dollars? In that case, you must specify how you want to transform the input by chaining a call to the `using` method like so; `s.from.number.to(Money).using(:cents)`

To see the full list of supported transformations and their names, you can look at the [FromString::ToTypeTransformRegistry](../lib/alchemrest/transforms/from_string/to_type_transform_registry.rb) and the [FromNumber::ToTypeTransformRegistry](../lib/alchemrest/transforms/from_string/to_type_transform_registry.rb).

### Block Transformations

In addition to these built in transformations, `to` also accepts a block argument to provide your own custom transformation logic. So for example, if you have a enum like input value that maps an actual class in your code with a bunch of flags, you could write a full chainable transform like this

```ruby
s.from.string.where.in(FinancialInstitution.keys).to(FinancialInstitution) { |input| FinancialInstitution.from_key(input) }
```

With a block transformation, AlchemREST will execute your block, and validate that it produces the expected output type, raising a transformation error if it does not.

### Custom transformations

Finally, you can also instruct AlchemREST on how to transform the input value using a `Morpher::Transform`. We cover how to create custom Morpher transforms in [Custom Transformations](./custom_transformations.md). If you have a transform you can invoke at like this

```ruby
s.from.string.where.in(FinancialInstitution.keys).to(FinancialInstitution).using(FinancialInstitution::Transform.new)
```

## Where (Yet again)

It's worth noting that after you've performed your transformation with a `to` call, you can actually chain additional constraints that will run against the output after the `to` transformation. At current we do not have any built in `where.<something>` style methods available, but you can use the block and custom constraint forms of where. You can see this in the example we started this document off with

```ruby
s.from.string.where.matches(/^\d+(?:\.\d{1,4})?$/).to(BigDecimal).where("less than 10") { |input| input < 10 }
```

So putting it all together, we can walk through the full pipeline defined here

1. `s.from.string` - ensures the input is a string
2. `.where.matches(...)` - ensure the input is a numeric string with between 0 and 4 decimal places
3. `.to(BigDecimal)` - converts the string to a BigDecimal
4. `.where("less than 10") { |input| input < 10 }` - ensures that decimal is less than 10

## Contributing to built in constraints and transformations

The constraints and type transformations infrastructure is designed to be highly scalable and modular to encourage growth of the built in options over time. If you find yourself reaching for a particular constraint or transform regularly, we strongly encourage you to submit a PR and add it to AlchemREST directly. In general, it only requires creating/modifying one or two classes.

### Adding Built in Constraints

To define a new `where.<something>` method, you first need to create a constraint class, as discussed in [Custom Constraints](#custom-constraints) above. Let's use our palindrome constraint as an example. We'll want to add this class to the [Constraints](../lib/alchemrest/transforms/constraint/) folder.

```ruby
module Alchemrest
  module Transforms
    class Constraint
      class IsPalindrome < self 
        def description
          "is palindrome"
        end

        def meets_conditions?(input)
          input.reverse == input
        end
      end
    end
  end
end
```

Second, you'll want to edit the relevant constraint builder class, either [ConstraintBuilder::ForString](../lib/alchemrest/transforms/constraint_builder/for_string.rb) for [ConstraintBuilder::ForNumber](../lib/alchemrest/transforms/constraint_builder/for_number.rb). Let's look at at the string builder below

```ruby
# frozen_string_literal: true

module Alchemrest
  module Transforms
    class ConstraintBuilder
      class ForString < self
        CONSTRAINT_METHODS = %i(max_length min_length matches).freeze

        def max_length(...)
          apply_constraint(Constraint::MaxLength.new(...))
        end

        def min_length(...)
          apply_constraint(Constraint::MinLength.new(...))
        end

        def matches(...)
          apply_constraint(Constraint::MatchesRegex.new(...))
        end
        
        # Other constraint methods
      end
    end
  end
end
```

In this class you just need to make two changes

1. Add a new method `def is_palindrome(...) = apply_constraint(Constraint::IsPalindrome.new(...))`
2. Add `is_palindrome` to `CONSTRAINT_METHODS`

This will then enable `s.from.string.where.is_palindrome`. Make sure you add test coverage for your constraint class, as well as for the constraint builder class itself.

### Adding Built in Type Transformations

Adding built in type transformations is slightly more difficult, only because you need to create a `Morpher::Transform`. We explain how to do this in [Custom Transformations](./custom_transformations.md), so read that first.

Once you have a working transform, you just need to register it. This is as simple as editing the appropriate registry file, either [FromString::ToTypeTransformRegistry](../lib/alchemrest/transforms/from_string/to_type_transform_registry.rb) or [FromNumber::ToTypeTransformRegistry](../lib/alchemrest/transforms/from_number/to_type_transform_registry.rb).

Here's an example of the string registry

```ruby
module Alchemrest
  module Transforms
    class FromString
      ToTypeTransformRegistry = BaseToTypeTransformRegistry.define(
        Time => [Alchemrest::Transforms::IsoTime.new],
        Date => [Alchemrest::Transforms::DateTransform.new],
      )
    end
  end
end
```

You can see this registry just consists of a call to our base registry's `define` method, with a hash passed in. The keys of this hash represent valid values for the first argument of `to`. They must be actual ruby classes. As you see above the values of this hash are arrays of `Morpher::Transform` instances. In this case, when you call `to(Time)`, Alchemrest will build a chainable transform that runs through each value of the array assigned to `Time` in order to create the output. So to add a new type simply add a new key to this hash and make it's value the array of 1 or more transforms you want to run to generate the output value.

If you have a situation where there are multiple possible transforms to produce a given type, then you can do something like what we have in the number registry here

```ruby
module Alchemrest
  module Transforms
    class FromNumber
      ToTypeTransformRegistry = BaseToTypeTransformRegistry.define(
        Money => {
          cents: [MoneyTransform.new(:cents)],
          dollars: [MoneyTransform.new(:dollars)],
        },
      )
    end
  end
end
```

You can see here that instead of an array, the value for the key `Money` is another hash. This hash has `Symbol` keys, and then array values. The symbols here serve as the list of valid arguments for `using` in the expression `to(Money).using(...)`. Alchemrest will use the symbol you provide to lookup into the nested hash, and get the array of transforms to use.
