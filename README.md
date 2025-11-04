# Alchemrest

A tool to help you transform third party api's into a set of classes and models designed to work nicely with your domain. Gives you a set of powerful interfaces to define data transformations, request clases, and organize common api calls into root objects

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alchemrest'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install alchemrest

In order to use the kill switch feature, you need to be using Rails and
ActiveRecord and you need to install and apply the migration:

    $ bundle exec rails generate alchemrest:kill_switch_migration
    $ bundle exec rails db:migrate

## Why Alchemrest?

Let's imagine you're working with an api with a GET endpoint at `/api/v1/users/:id`. By default in ruby you'll end up with code like

```ruby
require 'net/http'
require 'json'

url = 'https://my.api.com/v1/users/1'
uri = URI(url)
response = Net::HTTP.get(uri)
data = JSON.parse(response)
puts data["name"]
puts data["email"]
```

This has a couple of downsides in that it's verbose, requires working with dumb hashes rather than domain objects, and creates issues with reliability. Very quickly most of us start to reach for or develop tools that let us wrap responses in ruby classes, avoid parsing the data each time, etc. These tools often have their own problems though, creating code that invokes an api request behind the scenes, introducing brittleness because of api quirks and other issues.

Alchemrest helps solve these problems. With Alchemrest the above code can become

```ruby
api_root = MyApi::Root.new
user = api_root.get_user(1).unwrap_or_raise!
user.print_metadata
```

In the next section we'll take a look at how we set this up. For more about the philosophy behind our approach, check out [Philosophy](docs/philosophy.md)

## Quickstart

### Creating your client

The first thing you need to do is create an api client. This is just a class that implements `Alchemrest::Client`. So something like

```ruby
class Client < Alchemrest::Client
  # default configuration
  configure do |config|
    config.connection.url = "https://my.api.com/"
  end

  # default configuration + customizations on top
  configure do |config|
    config.connection.url = "https://my.api.com/"
    config.connection.customize do |c|
      c.options[:open_timeout] = 4
      c.options[:timeout] = 10
    end
  end

  # no defaults
  configure do |config|
    config.conneciton.url = "https://my.api.com/"
    config.connection.customize(use_default_middleware: false) do |c|
      c.use Alchemrest::FaradayMiddleware::UnderScoreResponse
      c.use Alchemrest::FaradayMiddleware::JsonParser
      c.use Alchemrest::FaradayMiddleware::ExternalApiInstrumentation, external_service: "new client"
      c.options[:open_timeout] = 4
      c.options[:timeout] = 10
    end
  end
end
```

As you can see, Alchemrest assumes you're using [Faraday](https://github.com/lostisland/faraday) as your http client. You can configure the faraday connection however suits your purpose, including any middleware or plugins that you'd like. Here we've got a very simple connection, using the default configuration

### Defining a request

Next, we need to define a request for the endpoint. That looks something like this

```ruby
class GetUser < Alchemrest::Request
  def initialize(id:)
    @id = id
  end

  endpoint :get, "/v1/users/:id" do |url|
    url.values = { id: @id } 
  end

  returns User
end
```

This is just a class that the inherits from `Alchemrest::Request`. On this class you only need to call 2 methods `endpoint` and `returns`.

First we'll talk about `endpoint`. Here, you're passing three arguments
* The http method for your request `get`, `post`, `patch`, `delete`, etc.
* The path for the endpoint.
* A proc to build a hash of any url parameters

For dynamic urls, you'll define the dynamic parts using rails routes syntax. (In the backend we use [mustermann](https://github.com/sinatra/mustermann/tree/master/mustermann) for path expansion)

Then we'll use the `proc` to get the dynamic values. The proc should return a hash with one key per path variable. Extra keys will be appended onto the url as query string parameters

Otherwise, the request object is just a normal ruby class. You can pass dynamic request params into the `new` method and store them as instance variables so you can access them in the proc. You can streamline things further using things like `ActiveModel::Model`

If your API returns an empty response you can simply omit the `returns` call - the result of the API call will be a `Alchemrest::Result::Ok(Alchemrest::Response)` or `Alchemrest::Result::Error(Alchemrest::ResponseError)` object.

Now we'll talk about the `returns` method in the next section

### Defining a Data Model

So on your request class, you saw a snippet of code like this

```ruby
returns User
```

In this case `User` is what we call a data model. Data models are classes meant to hold the information coming back from the api, and allow you to decorate the response with useful domain specific models.

To create a data model, just do something like this

```ruby
class User < Alchemrest::Data
  schema do |s|
    {
      required: {
        name: s.string,
        nickname: s.string.maybe,
        age: s.integer,
      }
    }
  end
end
```

So you see, we call a class method called `schema` with a block, and then inside that block we return a hash which defines the schema of the response.

The block gives you a schema helper which you can use to define the "transform" for each field. The transform is a special kind of function that will validate that the data is in the format you expect, and if necessary, transform it into something else. This helper exposes methods for every primitive like `s.string`, `s.integer`, `s.boolean`, and `s.float`. It also exposes some more advanced transformations like `s.enum` for lists of values, and `s.one_of` and `s.many_of` for nested objects.

Transforms are chainable, so you can do things like `s.string.array`. This means an array of strings. Or `s.string.maybe`. This means a string or a null. Every transform supports the following chainable methods

* `#array` - Ensure the source data is an array and then apply the original transform to every object in that array
* `#maybe` - If the source data is a nil, return nil, otherwise apply the original transform
* `#seq(transform)` - Apply the original transform, and then apply a new transform to that result

The `s` helper is meant to provide you transforms for a majority of use cases, but you can also write custom transforms. This will be covered in additional future documentation

### Defining your root

The last part of your setup is defining a root. A root is meant to give you an easy interface to your entire api. It makes it simple for developers to remember where to go to invoke an api call, encourages trust root chaining, and gives you a good place to compose multiple api calls when necessary.

A root looks like this

```ruby
class UserRoot < Alchemrest::Root
  use_client Client

  define_request :get_user, GetUser do |request|
    request.defaults = { id: id }
  end
  
  define_request :update_name, UpdateUserName do |request|
    request.defaults = { id: id }
  end

  attr_reader :id

  def initialize(id:)
    @id = id
  end
end
```

First, you define which api client to use for a root with `use_client`. Here `Client` refers to the `Alchemrest::Client` class we created earlier

Next, we're defining the requests that this root supports with the `define_request` class method. This accepts a symbol, which becomes the method name used to invoke the request, and the request class. You see here, we're creating a request for the class defined earlier `GetUser`, as well as for one not shown called `UpdateUserName`. The `with_params` argument to `define_request` allows us to use data defined on the root in our request. So we can write code like this

```
root = UserRoot.new(id: 1)
user = root.get_user
root.update_user_name(name: 'Billy')
```

See how we only have to provide the id for the user once, and then all requests off the same root will automatically use that user id.

Note the remaining code is just plain ruby used to setup your root and any shared data you need for your requests. You don't actually have to have it depending on your needs. So for example, here's a root for an api that doesn't operate on a discrete object like a user

```ruby
class FundsRoot < Alchemrest::Root
  define_request :get_all_funds, FundCollectionRequest
  define_request :get_fund, SingleFundRequest
end
```

Here you just have your individual requests defined on the root, with no intialization parameters.

Note you can have more than one root for a single api. With large complex apis that may even be desirable, since you can break the api down by domain segements as desired

## Accessing your data

With your root defined, now you can make calls like

```ruby
FundsRoot.new.get_fund(id: 1)
```

One thing you'll notice though is that  this method doesn't return a `Fund` as you might initially expect, it returns an `Alchemrest::Result::Ok`. `Alchemrest::Result` is a set of classes that we use to wrap api responses for safer handling of API responses. If the API server returns successful HTTP status code, we wrap the actual response data in a `Alchemrest::Result::Ok`. If it returns an unsuccessful code, then we wrap it in a `Alchemrest::Result::Error`.

You can unwrap the result in a few key different ways.

* `#unwrap_or_rescue` - Calling `FundsRoot.new.get_fund(id: 1).unwrap_or_rescue { nil }` will return the `Fund` instance for all successful requests, and nil for all unsuccessful.
* `#unwrap_or_raise!` - Calling `FundsRoot.new.get_fund(id: 1).unwrap_or_raise!` will return the `Fund` instance for all successful requests and raise the underlying error for unsuccessful ones
* Pattern matching - for more complex error handling, the `Alchemrest::Result` object supports ruby pattern matching. For more on this, see the detailed documentation [Working with Results](docs/working_with_results.md)

## Essential Reading

To make sure your intergration is production ready, and fully utilizes the power of Alchemrest, we recommend you read the following additiona documentation

* [Philosophy](./docs/philosophy.md) - The philosophy behind alchemrest and it's design decisions
* [Anatomy of an Alchemrest Integration](./docs/anatomy_of_an_alchemrest_integration.md) - A more complete overview of an end to end integration
* [Writing Tests](./docs/writing_tests.md) - A complete guide to testing your integration

## Upgrading

Alchemrest follows semantic versioning, so you should generally have no problem with bug fixes and minor version upgrades. For major version upgrades, we frequently aim to ship Alchemrest with rubocop rules that can be used to auto correct deprecated syntax. Below we've listed some cops you can use for particular version upgrades 

### Upgrading to V3

Version 3.0 includes the following breaking changes and rubocop rules to fix them

* The method signature for `Alchemrest::Request.endpoint` has changed. Instead of 3 positional arguments, with the third being a lambda returning a hash, the method now takes two positional arguments, and one block argument. The block argument recieves a `Alchemrest::UrlBuilder::Options` class, which offers a mutative api to modify the url template passed in via the secon position argument. You can autocorrect this with the cop [RequestHashReturningBlock](./alchemrest/lib/rubocop/cop/alchemrest/request_hash_returning_block.rb)
* Additionally, when using the new syntax above, you must separately define query string parameters from dynamic url parameters. You can autocorrect this with the cop [EndpointDefinitionUsingGenericParams](./alchemrest/lib/rubocop/cop/alchemrest/endpoint_definition_using_generic_params.rb). Note this correction is not safe, in that we assume all exisiting params are url values. You need to audit all corrections to identify which ones should be query string params.
* The method signature for `Alchemrest::Root.define_request` has changed. We have dropped the `with_params:` kwarg. Now to set default initialization parameters for the request you should do the following
```ruby
define_request :get_users, GetUsers do |request|
  request.defaults = { user_id: }
end
```
You can autocorrect this with the cop [DefineRequestUsingWithParams](./alchemrest/lib/rubocop/cop/alchemrest/define_request_using_with_params.rb)
* The syntax for defining a transform from a `String` to `Time` has changed, and you're required to specify what timezone you want to parse the string using. Generally for full ISO strings that include a timezone offset, this won't matter, but if the ISO string does not include an offset, specifying a timezone is very important, as UTC is assumed by default, and might not be right. You can autocorrect this using the cop [TimeTransformWithNoZone](./alchemrest/lib/rubocop/cop/alchemrest/time_transform_with_no_zone.rb)

## Learn more

For more advanced explanations of how alchemrest works and how to use it, check out the [Docs folder](./docs).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md)
