# Working with Data Classes

Data classes are a key part of using AlchemREST. In general the goal of data classes is to give us a Ruby class that wraps the raw JSON data coming back from an api. With a data class, we move away from whatever simple primitives provided by the api to a rich domain object which uses more interesting types (ie Money and Time objects instead of integers and string), and can be decorated with useful domain methods.

AlchemREST is designed to be flexible about how you implement your data classes, and you don't have to use the tools that ship with AlchemREST to build and manage your data, but we have a baked in set of tools which make use of the [Morpher](https://github.com/mbj/morpher) transformations library to give us tooling for safe and flexible transformations of data.

As we walk through using data classes, we'll use examples that imagine we're integrating with a banking api offered by the fictional company Bank.com. The AlchemREST integration for this api can be found in [Dummy Integration](../alchemrest/examples/bank_api). All the examples covered in this document can also be found in our [Integration Tests](../alchemrest/spec/integration).

## Basic Setup

To create a data class, you start by inheriting from `Alchemrest::Data`, and then using the `schema` macro. So here's an example.

```ruby
module BankApi
  module Data
    class User < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            status: s.enum(%w(open locked)),
            date_of_birth: s.from.string.to(Time).using(:utc),
            account_ids: s.integer.array,
          },
          optional: {
            nickname: s.string,
          },
        }
      end
    end
  end
end
```

When this class is instantiated by AlchemREST as part of the HTTP response handling process, you'll end up with an object where you can call any of the attributes defined by `schema` as methods like `user.name` or `user.status` etc.

You'll also see that each key in the hash returned in `schema` has a value that tells you something about the type of the data. These are "transformations". These help guarantee the data is of a particular type, and/or transforms it into a more useful domain type.

## Transformations

Transformations are at the heart of AlchemREST's data conversion process. Under the hood transformations are implemented using the library [Morpher](https://github.com/mbj/morpher). Morpher gives us a flexible, composable interface to define data pipelines that validate data coming in the expected format, and also transform it to a desired output.

Before we try to understand how transformations work, it's important to note AlchemREST approaches the problem of converting JSON into domain models with a philosophy of strict parsing at it's heart. This means that we try not to make assumptions about the data, or coerce into a particular type unless we're sure it fits that type. The idea is that we should be paranoid about the data we get from third parties, and make sure it really meets our expectations before passing it along to downstream code. In practice this means we check the response data in a number of different ways before transforming it into our data class. If it fails any of those checks, we'll return an `Alchemrest::MorpherTransformError` wrapped by an `Alchemrest::Result::Error`.

Let's take a look at the class above and walk through the set of transformations we're using here so you can get a sense of how to use this core part of AlchemREST.

Starting at the top, you can see we've first sorted our keys into two categories, `required` and `optional`. Any keys listed in `required` have to be present in the response, even if their value is null. Any keys in optional, don't have to be there. For optional columns, the attributes will still exist on the model, they'll just be nil (ie `user.nickname => nil`).

One important thing to note is that if the response includes some kind of extra column, like `address`, we do not treat that as an error. If you don't want to allow optional keys, then you can use the option `allow_additional_properties: false`, which you add as an additional key alongside `required` and `optional`

```ruby
{
  required: {...},
  optional: {...},
  allow_additional_properties: false
}
```

Nested within each of the `required` and `optional` hashes, each key corresponds to an attribute in the response. The value is one of our "Transform" objects, built up using [Morpher](https://github.com/mbj/morpher).

So let's look at each of the transforms in our `required` block. First you see `name: s.string`. In this case the `s` is just a helper module off which we hang all the built in transforms that AlchemREST ships with. And so `s.string` returns a transform that simply makes sure the input is a string, and performs no additional transformation.

Now let's look at the next line. Here we have `status: s.enum(%w(open locked)`. This is a little more interesting. Here we call the function `enum`, and pass in a list of strings. This will return a `Alchemrest::Transforms::Enum` transformation initialized with the list of strings provided. The `Enum` transform validates that the input data is one of the provided values, and then symbolizes it. Additionally `Enum` supports a hash as an initialization parameter, in which case it will validate that the input is in the list of keys, and it will transform the output to the corresponding value.

These first two examples are relatively simple, but this next one is more interesting. `date_of_birth: s.from.string.to(Time).using(:utc)` Here, we're making use of a flexible interface we call "Chainable Transforms". We'll cover this more in its own section [Chainable Transforms](./chainable_transforms.md), but we'll do a quick run down now.

The idea behind chainable transforms is you start by identifying what your input data looks like using `s.from.string` or `s.from.number`. After that you can further constrain your data by chaining on a series of where statements. So `s.from.string.where.max_length(10)` will validate that your input data is a string which is 10 characters or less. Next, you can transform the data by using a `to` call, like `s.from.string.where.max_length.to(Time)`.

So now let's come back to our example above `date_of_birth: s.from.string.to(Time)`. Here we have a transform that validates our input as a string, ensures it's in a format that is valid ISO, and then converts it to a time object.

Now let's look at the last line `account_ids: s.integer.array`. This shows off another useful feature of transforms. All transforms, both the "Chainable Transforms" and the more simplistic one have an interface that let you handle derived types. So for example, something that is either a number or null would be `s.number.maybe`. An array of numbers would be `s.number.array`.

Full documentation on all the built in transformations can be found in the comments for [Alchemrest::Transforms](../alchemrest/lib/alchemrest/transforms.rb) and the above mentioned [Chainable Transforms](./chainable_transforms.md). You can also create custom transformations. We cover this topic in [Custom Transformations](./custom_transformations.md)

### Nested data

In many cases, API responses from third parties can be deeply nested, such that the value of a particular key is another hash, rather than a simple data type. In those cases you can use the `s.one_of` and `s.many_of` transformations. Both of these transformations let you pass in a second `Alchemrest::Data` class that will handle the nested structure like this.

```ruby
module BankApi
  module Data
    class Card < Alchemrest::Data
      schema do |s|
        {
          required: {
            source_type: s.enum(%w(card)),
            card_number: s.string,
            expiration_date: s.from.string.to(Time).using(:utc, require_offset: false),
          },
          optional: {
            secondary_user: s.one_of(User)
          }
        }
      end
    end
  end
end
```

If the key in question is polymorphic, then you can pass in multiple objects and define how to select between them based on the data. To do this, you pass a hash to `s.one_of` or `s.many_of` like this

```ruby
module BankApi
  module Data
    class Transaction < Alchemrest::Data
      schema do |s|
        {
          required: {
            # other fields ...
          },
          optional: {
            source: s.one_of(
              check: BankApi::Data::Check,
              card: Bank::Api::Data::Card,
              ach: Bank::Api::Data::Ach,
              discriminator: :source_type,
            )
          },
        }
      end
    end
  end
end
```

The key "discriminator" indicates which field of the nested object will define the "type" value we can use to figure out which polymorphic type we're dealing with. Then the other values of the hash map the value of that field (`:source_type` in this case) to an actual `Alchemrest::Data` class. (Note this currently requires that the polymorphic types have a single consistent field you can use to distinguish between them, although we are exploring making it possible for `discriminator` to be a lambda for more flexibility)

### Handling Errors

As noted above, when things go wrong we return an instance of `Alchemrest::MorpherTransformError` wrapped in an `Alchemrest::Result::Error`. Generally, we assume that you'll see these errors when you call `unwrap_or_raise!` and `unwrap_or_rescue`. When this happens, we try to generate an error message that helps you understand that the response didn't match the expected schema. So for example, imagine that we get a user response where the status field is `reactivated`. The transformation we've defined for this field is `status: s.enum(%w(open locked))`, meaning we only expect the values to be “open” and “locked”. This will generate an error that looks like.

```shell
Response does not match expected schema - Morpher::Transform::Sequence/2/Alchemrest::Transforms::LooseHash/[:status]/Alchemrest::Transforms::Enum: Expected: enum value from ["open", "locked"] but got: "reactivated"
```

This string is showing you the path to the error, and then the error itself. Each `/` in the string represents a step in the transformation process.

The first part `Morpher::Transform::Sequence/2/Alchemrest::Transforms::LooseHash` is some boilerplate involved in every `Alchemrest::Data` transformation. After that you get the value `:status` indicating the problem is with the status attribute, and then `Alchemrest::Transforms::Enum` indicating it failed the enum transformation/checks. Finally we get the actual error message, indicating what value the API did provide.

For nested models, you'll be able to see the full path through the model tree, to the field that's failing.

## Decorating Data

Initially when you set up your data models, they'll look really similar to the actual API responses. However, overtime, you'll likely find that there are certain operations you do over and over again in your code. Maybe it's adding the values of a few fields up, maybe it's creating nicely formatted strings of certain values to display to the user, etc. Here is where AlchemREST can really start to shine. Because your `Alchemrest::Data` classes are just normal Ruby objects, you can add your own methods to them. Take a look at our `BankApi::Data::User` class

```ruby
module BankApi
  module Data
    class User < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            status: s.enum(%w(open locked)),
            date_of_birth: s.time(:iso),
            account_ids: s.integer.array,
          },
          optional: {
            nickname: s.string,
          },
        }
      end

      def age
        Time.zone.now.year - date_of_birth.year
      end
    end
  end
end
```

At the bottom of this class, we've added an `age` method, which calculates a user's current age based on the birthdate from the API response. (Nevermind that our formula for getting an age is horribly incorrect, we just wanted a simple one line example).

This also serves as a great way to alias data. Maybe you're not a fan of how the third party API has named a handful of fields, because you use different terminology in your main app code, or it conflicts with other domain concepts you use regularly. You can use the standard `alias` helpers in Ruby to create your own aliases for any fields.

In general, any kind of mixins, helpers or techniques you use with plain old Ruby objects elsewhere in your codebase will be compatible with your `Alchemrest::Data` objects, giving you a lot of flexibility to make these classes integrate really well with your codebase.

In a similar vein, you can also flatten very nested data structures using AlchemREST. Let's look back at the `BankApi::Data::Transaction` class which has a nested structure

```ruby
module BankApi
  module Data
    class Transaction < Alchemrest::Data
      schema do |s|
        {
          required: {
            amount_cents: s.money(:cents),
            status: s.enum(%w(completed pending)),
            settled_at: s.time(:iso),
            description: s.string,
          },
          optional: {
            source: s.one_of(
              check: BankApi::Data::Check,
              card: BankApi::Data::Card,
              ach: BankApi::Data::Ach,
              discriminator: :source_type,
            ),
          },
        }
      end
    end
  end
end
```

Let's say I want an easy way to get at the source identifier field that exists for every polymorphic source type. I can add a new method to `Transaction` like this

```ruby
def source_identifier
  case source
    when BankApi::Data::Check
      source.check_number
    when BankApi::Data::Card
      source.card_number
    when BankApi::Data::Ach
      source.trace_number
    else
      nil
  end
end
```

Now my calling code can call `transaction.source_identifer` so I don't have to drill through the nested structure.

With deeply nested models, this can significantly streamline code for accessing that nested data.

## Testing With Data

Generally, our data models get built up by the AlchemREST framework as part of the request lifecycle. However, during testing, you may find it convenient to create instances of models directly.

Generally, the best way to do this is to use the `from_hash` method. So for example, if I want to create a new transaction to test my `source_identifier`. I can write

```ruby
transaction = BankApi::Data::Transaction.from_hash(
  amount_cents: 120_00,
  status: "completed",
  settled_at: "2023-10-10T00:00:00",
  description: "check transaction",
  source: {
    source_type: "check",
    check_number: 100,
    check_image_back_url: "#{BankApi::Client::API_URL}/api/v1/check_images/100/back.png",
    check_image_front_url: "#{BankApi::Client::API_URL}/api/v1/check_images/100/front.png",
  },
)
```

This will run all the same validations and transformations run by the request process, ensuring your test behavior lines up with production behavior.

We cover more testing concerns in a separate document [Writing Tests](./writing_tests.md)

## Handling Empty Responses

Sometimes API endpoints return empty responses, particularly for actions like DELETE or certain PUT/PATCH operations where no content is returned (HTTP 204 No Content). In situations, the endpoint always returns a 204, you can just avoid using `returns` at all, like below

```ruby
module BankApi
  module Requests
    class DeleteUser < Alchemrest::Request

      def initialize(id:)
        @id = id
        super
      end

      endpoint :delete, '/api/v1/users/:id' do |url|
        url.values = { id: @id }
      end
    end
  end
end

result = api.delete_user(id: 123)
# result will be Alchemrest::Result::Ok(response) which gives you the raw response include the status
```

In more rare circumstances you may have an endpoint that returns something you want to map to a data object some of the time, but a 204 in other situations. Let's imagine an update endpoint where returns a 204 if you make no changes, but returns a User response if you changed a value. In this case you can use `returns` with the argument `allows_empty_response: true`

```ruby
module BankApi
  module Requests
    class UpdateUser < Alchemrest::Request

      def initialize(name:, date_of_birth:)
        @name = name 
        @date_of_birth = date_of_birth
        super
      end

      endpoint :patch, '/api/v1/users/:id' do |url|
        url.values = { id: @id }
      end
      
      def body
        { 
          name: @name,
          date_of_birth: @date_of_birth,
        }
      end
      
      returns User, allow_empty_empty_response: true
    end
  end
end

result = api.update_user(id: 123)
# result will be Alchemrest::Result::Ok(User) or Alchemrest::Result::Ok(nil)
```

## A special note on Time and Timezones

As anyone who has worked with time and timezones can tell you, there's always a lot of complexity lurking behind what seems like a simple problem. AlchemREST does its best to help you navigate that complexity by offering a set of sane defaults, and tooling to tweak how you handle time strings from an API to your specific needs.

Here are the general principles of how we support times

* We have built in support for time strings in the ISO8061 format
* We default to requiring that all timezones include an offset component (although you can override this and opt into supporting strings with no offset)
* We have our transforms return either a `Time` or an `ActiveSupport::TimeWithZone` depending on the kind of transform you build

As a result, the key decisions you have to make are as follows

* Do I need to support offset-less strings?
* Do I want to parse my times into a specific zone?

AlchemREST generally recommends that you answer these questions "No" and "Yes" respectively, and our defaults push you towards that.

### A good starting point

If you're not sure what to do or how to answer those above questions, we recommend you start with

`s.from.string.to(Time).using(:local)`. This will result in the following behavior

1. Any string that's missing an offset will result in transform error
2. The transform will return an `ActiveSupport::TimeWithZone` in the timezone defined by `Time.zone`, accounting for the original offset value in the string. In many ways this will mimic how time values are loaded from the database. It also ensures methods like `.to_date` will return the correct date for your given application time zone.

This is probably the safest, most typical kind of transformation you want. If it turns out the API you're integrating
with doesn't include offsets, then keep reading

### No offsets

Some API's don't return offsets for their time strings. This can be a little tricky to interpret. You'll have to read the API documentation or talk to the API author to understand what timezone these strings are supposed to be in. Is it utc? Is it the local timezone of the server? Is this a situation where it's really a date field that they've just added a time component to? Based on what you discover you'll want to do something like this

`s.from.string.to(Time).using('Eastern Time (US & Canada)', require_offset: false)`. This will result in the following behavior

1. If the offset is missing, AlchemREST will assume the timezone the first param into passed into `using`
2. If the offset is present, AlchemREST will build a time object using that offset, and then convert it to the timezone defined by the first param into `using`, properly adjusting the time.

Note the timezone strings are all those supported by `ActiveSupport::TimeZone`. We also support the symbol `:utc` for `'UTC'`

### Want all times in another timezone

Maybe you want all time objects to be in your utc, or another zone, because you are doing certain kinds of comparisons with data from another source that uses a particular zone, or you're converting from times to dates in a different zone. In that case you can do

`s.from.string.to(Time).using('Easter Time (US & Canada')`. This will result in the following behavior

1. If the offset is missing, AlchemREST will create a transform error
2. The transform will return an `ActiveSupport::TimeWithZone` in the timezone defined the first parameter, accounting for the original offset value in the string

### Want to preserve the original string, with the original offset included

Maybe you expect values in a bunch of different timezones and you want to preserve which offset was actually defined by the API object, and not convert to a specific, consistent timezone. In that case you can use

`s.from.string.to(Time).using(:offset)`. This will result in the following behavior

1. If the offset is missing, AlchemREST will create a transform error
2. The transform will return a `Time` object, with the offset defined by the original string. Note it does not return `ActiveSupport::TimeWithZone`. This is because an ISO string by itself does not tell us what timezone the time is in. It just tells us the offset, which cannot be reliably mapped to a specific zone because of issues with DST, overlapping zones, etc.

This makes `offset` a particularly niche tool, for specific use cases. Generally you probably want to ensure all your time objects are in a particular zone based on your needs and use case. The only time you need `offset` is if you really need to preserve the actual offset from the original string sent by the API

### The API I'm integrating with doesn't use ISO at all

In that case [Custom Transformations](./custom_transformations.md) will be your friend. Setup a transformation based on whatever format the API does use. However, do make sure to consider the problems highlighted above. Ask yourself what offset or timezone the data you're getting back from the API is supposed to be in. Consider what zone you'd like your in memory representation to be in, and setup your custom transformation accordingly

## Example Transforms for common scenarios

Below we've listed a handful of examples for common transformations 

**Validating UUID strings**
```ruby
# With explicit where
s.from.string.where.must_be_uuid

# Optional where syntax
s.from.string.must_be_uuid
```

**Validating phone numbers in E.164 format**
```ruby
# With explicit where
s.from.string.where.matches(/^\+?[1-9]\d{1,14}$/)

# Optional where syntax
s.from.string.matches(/^\+?[1-9]\d{1,14}$/)
```

**Validating URL strings**
```ruby
# With explicit where
s.from.string.where.matches(/\Ahttps?:\/\/.+\z/)

# Optional where syntax
s.from.string.matches(/\Ahttps?:\/\/.+\z/)
```

**Constraining string length (e.g., account numbers, routing numbers)**
```ruby
# With explicit where
s.from.string.where.max_length(15)

# Optional where syntax
s.from.string.max_length(15)
```

**Requiring strings within a length range**
```ruby
# With explicit where
s.from.string.where.min_length(3).max_length(50)

# Optional where syntax
s.from.string.min_length(3).max_length(50)
```

**Validating string is from a known list**
```ruby
# With explicit where
s.from.string.where.in(['pending', 'active', 'completed', 'failed'])

# Optional where syntax
s.from.string.in(['pending', 'active', 'completed', 'failed'])
```

**Ensuring numbers are positive (greater than zero)**
```ruby
# With explicit where
s.from.number.where.positive

# Optional where syntax
s.from.number.positive
```

**Ensuring numbers are non-negative (zero or greater)**
```ruby
# With explicit where
s.from.number.where.non_negative

# Optional where syntax
s.from.number.non_negative
```

**Ensuring numbers are integers (not floats)**
```ruby
# With explicit where
s.from.number.where.integer

# Optional where syntax
s.from.number.integer
```

**Constraining numbers to a specific range (e.g., ratings, percentages)**
```ruby
# With explicit where
s.from.number.where.greater_than_or_eq(0).less_than_or_eq(100)

# Optional where syntax
s.from.number.greater_than_or_eq(0).less_than_or_eq(100)
```

**Converting monetary amounts in cents to Money objects**
```ruby
s.from.number.to(Money).using(:cents)
```

**Converting monetary amounts in dollars to Money objects**
```ruby
s.from.number.to(Money).using(:dollars)
```

**Converting decimal strings to BigDecimal (e.g., interest rates, percentages)**
```ruby
# With explicit where
s.from.string.where.matches(/^\d+(?:\.\d{1,4})?$/).to(BigDecimal)

# Optional where syntax
s.from.string.matches(/^\d+(?:\.\d{1,4})?$/).to(BigDecimal)
```

**Converting percentage strings with range validation**
```ruby
# With explicit where
s.from.string.where.matches(/^\d+(?:\.\d{1,4})?$/).to(BigDecimal).where("between 0 and 1") { |val| val >= 0 && val <= 1 }

# Optional where syntax
s.from.string.matches(/^\d+(?:\.\d{1,4})?$/).to(BigDecimal).where("between 0 and 1") { |val| val >= 0 && val <= 1 }
```

**Arrays of validated values (e.g., lists of UUIDs)**
```ruby
# With explicit where
s.from.string.where.must_be_uuid.array

# Optional where syntax
s.from.string.must_be_uuid.array
```

**Optional values with validation (e.g., optional country codes)**
```ruby
# With explicit where
s.from.string.where.matches(/^[A-Z]{2}$/).maybe

# Optional where syntax
s.from.string.matches(/^[A-Z]{2}$/).maybe
```
