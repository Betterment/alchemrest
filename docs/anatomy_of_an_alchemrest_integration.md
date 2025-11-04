# Anatomy of an AlchemREST Integration

The [README](../README.md) does a quick overview of the different parts of an AlchemREST Integration. In this document, we will try to dig deeper and provide more clarity on each piece of that integration, and how they work together, working out from the http layer, to the objects you interact with in the domain.

For the purpose of this work, we'll imagine a fictional company, Bank.com, which offers a banking API you can use to manage users, create accounts, and perform transactions.

The examples in this file are also available in the [Dummy Integration](../spec/dummy/bank_api) we use for integration testing. You can review the example integration code in that folder, as well as [Integration Tests](../spec/integration) that use it for real.

## App Level Configuration

AlchemREST contains a few app level configuration features, although most things are configured on a per API integration basis. We'll outline the top level configuration options here for reference.

* `Alchemrest.on_result_rescued {}` - Configures what Alchemrest should do if it rescues an error when using the `Alchemrest::Result#unwrap_or_rescue` method. See [Error Handling Patterns](./error_handling_patterns.md) for more detail. The block will receive the rescued error, which will be one of the types defined in `Alchemrest.rescuable_exceptions`. Generally you want to hook this up to your exception management system to ensure you have visibility until rescued results (ex Sentry, etc).
* `Alchemrest.rescuable_exceptions=` - The list of exception classes that should be rescued when using `unwrap_or_rescue`. By default this includes all http related errors (including faraday timeouts and ssl errors), and a few other AlchemREST specific error types. If changing this list you should probably start with `Alchemrest::DEFAULT_RESCUABLE_EXCEPTIONS` and then add your own additional types like `[*DEFAULT_RESCUABLE_EXCEPTIONS, MyOtherExceptionClass]`
* `Alchemrest.logger=` - The logger to be used for the default behavior of `on_result_rescued`. Note if you override `on_result_rescued` this value isn't used at all. Defaults to stdout.

## Client

The client is the core layer that sits between AlchemREST, and the raw http layer provided by Faraday. The client has two responsibilities.

1. Build a `Faraday::Connection` that we'll use to actually execute the http requests
2. Convert raw `Faraday::Response` objects into integration specific response objects that customize behavior for things like extracting error messages, or other low level, cross cutting, API concerns.

The idea is that this class will handle all the http request and response related concerns that are common across all the endpoints of the API you're calling.

For the most part, this mostly means setting up middleware for your Faraday connection. In general, at a minimum, you need middleware that converts a raw JSON response to a hash to be fed into your data models downstream. But on top of that you can also use middleware to do some of the following

* Convert camel case JSON property names to underscore hash keys for more idiomatic Ruby syntax in your data models
* Add logging for all outbound requests
* Setup authentication

AlchemREST ships with a few middleware implementations for some of these things, but it's also easy to write your own. See the docs on [client configuration and middleware](./client_configuration_and_middleware.md) for more details on this.

Aside from middleware, the other thing you may want to do is customize how errors are extracted from API responses. Some API's put all their errors in a dedicated `errors` array. For others the `errors` key is a hash. And others will put the errors mixed in with the fields they apply to.

By default, AlchemREST doesn't attempt to extract any errors from the response. But you can override that by implementing your own `Alchemrest::Response` class, with a customized `error_details` method. This method should return a hash, array, or string, depending on how you want to show and pattern match the data.

To ensure your client uses the custom class, you'll also need to override the `Client#build_response` method.

For an example see the client for the dummy app.

## Requests

The next piece of an AlcheREST API integration is your request models. These are the classes that describe the details for how to make requests to each endpoint in the API you're calling. Each request model defines an http method, and a url pattern which can be fully static, or include dynamic portions. For post requests, you also need to define a `def body` method, which returns the hash that will be posted with the request as JSON.

Generally, you'll setup a request model by inheriting from `Alchemrest::Request` and then using the
`endpoint` class method to define the url and method. `endpoint` takes 2 required parameters and yields to a block. The two parameters are

* http method - Either :get, :post, :put, or :delete
* url - a string, of either a fully static url, or a [Mustermann](https://github.com/sinatra/mustermann) style url template

Within the block you can further control how the path is built up. The block gives you a `Alchemrest::UrlBuilder::Options` instance, which exposes the following setters

* `values=` - A hash to have a Mustermann user to replace the dynamic portions of the url. Note the block is executed in the context of your request class instance, so you can access all methods and local variables to get those dynamic portions
* `query=` - A hash of query string values you'd like to add to the url
* `encode_query_with=` - Can be set to either `:rack` or `:form`. Controls how the query string parameters are encoded. If `rack` we use `Rack::Utils.build_nested_query`. If `:form` we use `URI.encode_www_form`. If you're talking to a rails API that expects query strings like `?array_item[]=1&array_item[]=2` for complex array parameters, you'll want to use `:rack`.  

You can also pass a completely custom encoder in using `encode_query_with { |query| ... }`. This method takes a block which will receive the query hash as an argument, and should return a string that will be tacked on to the url. You can omit the `?` as that will be added automatically.

Here's an example request class using the `endpoint` class method

```ruby
module BankApi
  module Requests
    class GetUser < Alchemrest::Request
      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end
 
      endpoint :get, '/api/v1/users/:id' do |url|
        url.values = { id: @id }
        url.query = { includeDetails: true }
      end
    end
  end
end
```

So if we call `BankApi::Requests::GetUser.new(id: 1).path` we'll get `/api/v1/users/1?includeDetails=true`

Once you've got a request class setup like this you can call

```ruby
result = BankApi::Client.new.build_http_request(BankApi::Requests::GetUser.new(id: 1)).execute!
```

This will return an `Alchemrest::Result` class that wraps the response. Calling something like

```ruby
result.unwrap_or_raise!.body
```

Gives you the raw body of the response. Of course, you probably don't want to work with the raw body, you want to work with a domain model. To support that, you can set a `response_transformer` for your request class. This is a function that converts the `Alchemrest::Response` into some sort of Ruby object.

Typically you'll want to setup the `response_transformer` by using the `returns` class method, like in the below request

```ruby
module BankApi
  module Requests
    class GetUser < Alchemrest::Request
      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      returns BankApi::Data::User
      endpoint :get, '/api/v1/users/:id' do |url|
        url.values = { id: @id }
        url.query = { includeDetails: true }
      end
    end
  end
end
```

This will set a transformer that's compatible with `Alchemrest::Data` classes. This is really the only built-in transformer, but if you want to write a custom transformer, then you can do so, and modify your class to set the `@response_transformer` class instance variable. This variable should hold an object or lambda which has a `call` method that can take in the `Alchemrest::Response` and safely produce whatever output you want.

Additionally, in situations where your request returns a collection, you can write something like `BankApi::Data::User[]`. Every AlchemREST `Data` class defines a method `def self[]` which returns a sub class that's setup to support parsing collections of the class.

Finally, maybe your API nested the actual user payload inside some top level keys, like this

```ruby
{ 
  data: {
    user: {
      name: "John"
      # other user props
    }
  }
}
```

in that case, you can pass the `path_to_payload` argument to `returns` like so

```ruby
module BankApi
  module Requests
    class GetUser < Alchemrest::Request
      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      returns BankApi::Data::User, path_to_payload: %i(data user)
      endpoint :get, '/api/v1/users/:id' do |url| 
        url.values = { id: @id } 
      end
    end
  end
end
```

Now AlchemREST will dig down like `body["data"]["user"]` and feed the output of that into your data class

Post requests are pretty similar. Here's a sample post request.

```ruby
module BankApi
  module Requests
    class PostTransaction < Alchemrest::Request
      include ActiveModel::Model
      attr_accessor :account_id, :id, :amount

      endpoint :post, '/api/users/:id/accounts/:account_id/transactions' do |url|
        url.values = { id: id, account_id: account_id }
      end

      def body
        { amount: amount }
      end
    end
  end
end
```

The one difference you'll see, is now we have a `def body` method in the class. This is where we define the POST body. You'll also notice this particular post request does not use the `returns` macro. This is because our bank.com API doesn't return any kind of data for a successful post, just a 204 status. So if we call

```ruby
result = BankApi::Client.new.build_http_request(
  BankApi::Requests::PostTransaction.new(id: 1, account_id: 2, amount: 100)
).execute!
```

This will return an `Alchemrest::Result` class that wraps the raw response.

Lastly, in some cases you may have a need to provide custom per request headers for a particular request. This can be particularly useful if you have an API that needs to provide a customer specific OAuth token, or something like that. In that case you can override the `def headers` method of the request class as follows

```ruby
module BankApi
  module Requests
    class GetBusinessAccount < Alchemrest::Request
      include ActiveModel::Model
      
      attr_accessor :token, :id

      endpoint :get, '/api/business_accounts/:id' do |url|
        url.values = { id: id }
      end 
      
      returns BankApi::Data::BusinessAccount

      def headers
        { Authorization: "Bearer #{token}" }
      end
    end
  end
end
```

## Data Models

In the above section we alluded to `Alchemrest::Data`. This is the class we use to build what we call "Data Models". Data Models are Ruby objects to represent the data we get back from an API. A data model has 3 key purposes

1. Provide access to individual values from the response via dot notation (ie `user.date_of_birth`)
2. Validate that incoming values from the response fit the shape you expect (ie making sure `user.date_of_birth` will always be a date)
3. Provide place to add new methods that transform and manipulate the raw data from the response  (ie adding `user.age` which uses `user.date_of_birth` to calculate the users current age)

Out of the box, we support creating data models using the `Alchemrest::Data` class, which uses the data transformation library [Morpher](https://github.com/mbj/morpher) behind the scenes. To create a data model using this class just do the following

```ruby
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
    Time.zone.now.year - date_of_birth.year # NOTE: This isn't actually correct, just an example
  end
end
```

Let's break down what's happening here.

The `schema` macro does some meta programming via the Morpher library that sets up a constant `User::TRANSFORM`. This constant is an instance of `Morpher::Transform` which can convert a hash of data into a `User` record, validating the data as it goes. The validations it performs are that

* The incoming hash has a key named `name` with a string value
* The incoming hash has a key named `date_of_birth` with an iso string that can be parsed into a date time
* If the hash has a key named `nickname`, it's a string (although it doesn't have to have that key).

You can see these validations by looking at `Alchemrest::Data::Transforms`, which contains all the schema helper methods exposed by `s` in the example above. Each of these methods loosely wraps a Morpher transform that validates the data is in a particular expected format, and then optionally transforms it

So for example the `date_of_birth` value is passed through the `s.time(:iso)` method, which creates an instance of `Alchemrest::Data::Transforms::IsoTime`. This transform makes sure the string is an iso time string, and then converts it into a date time using `Time.iso8601`. You can see how the `Alchemrest::Data::Transform` provides a number of helpers for different data types that build up and invoke the transforms for you. Note, you can create your own custom transforms and use them directly, which we cover in the [Custom Transformations](./custom_transformations.md) section of this documentation

Sometimes you may want to create an instance of a data model without going through the request process, particular for testing. You can do this using the `self.from_hash` method. This will run the same transformations and validations as the request code, so it ensures your tests remain accurate as your model evolves.

You can also new up an instance of the model directly, but this is generally not recommended. This will not perform most validations, and has some quirks in how optional attributes are handled. You must provide the optional attributes, but with a nil value.

Note while the out of the box configuration is designed to work with data models created using `Alchemrest::Data::Transform`, you can customize AlchemREST to have your own way of building data models. You just need to define your own response transformer that can take an `Alchemrest::Response` and build your model class, and then set `@response_transfomer` on your request model. We also cover this in the [Custom Transformations](./custom_transformations.md) section of this documentation.

## The Root

The last piece of your AlchemREST integration is one or more `Alchemrest::Root` classes. The purpose of a root is to present a singular, easy to consume interface to the API (or to a subset of the API).

1. A series of methods that make it easy to invoke requests defined by `Alchemrest::Request` classes
2. Additional custom methods that wrap these request methods and do things like data transformation, memoization, etc.
3. Error observation and limited side effects in response to errors

Here's an example root from our dummy app

```ruby
class BankApi::Root < Alchemrest::Root
  extend Memosa
  attr_reader :id

  def initialize(user_id:)
    @id = user_id
  end

  use_client BankApi::Client
  define_request :get_user, BankApi::Requests::GetUser do |request|
    request.defaults = { id: id } 
  end
  
  define_request :post_transaction, BankApi::Requests::PostTransaction do 
    request.defaults = { id: id } 
  end
  
  define_request :get_transactions, BankApi::Requests::GetTransactions do 
    request.defaults = { id: id } 
  end

  on_alchemrest_error do |error|
    case error
    in { status: 401 }
      Alchemrest.logger.info "Credentials expired"
    else
      nil
    end
  end
  
  memoize def all_transactions
    Alchemrest::Result.for do |try|
      user = try.unwrap get_user
      user.account_ids.map { |i| try.unwrap get_transactions(account_id: i) }.flatten
    end
  end
end
```

Let's break down what's going on here.

First we call `use_client` to indicate which `Alchemrest::Client` class we should be using for our root. After that we use `define_request` to set up three methods which will invoke our request classes. After this we can write code like.

`BankApi::Root.new(1).get_user.unwrap_or_raise!.name`

This is helpful, but what if we have a situation where we need to show all the transactions a user has performed across multiple bank accounts. Imagine that the API we're working with only lets you get all the transactions for one account at a time. Here's where the root can be a helpful place to hang new methods that abstract our calling code from API implementation details like that. Look at the `all_transactions` method. This handles getting the users account ids, and then making one request per account to get all the transactions. Since this is an expensive operation, it also memoizes that data, so subsequent calls are faster.

The other things worth noting is how we make use of `with_params` for many of the requests. The API is initialized with a user's id, and then we can use that id with all of our requests to avoid passing the param over again. Aside from being more convenient, this also helps support secure trust root chaining, opportunities for memoization.

Finally we call `on_alchemrest_error` and set up a simple logger to log a special message for 401 errors. `on_alchemrest_error` is meant to serve as a place to "observe" errors across the entire root and take action on them. It's a good fit for logging common error scenarios across an entire API (or whatever subset of an API the root handles), and for taking limited actions based on what you observe. Good fits for `on_alchemrest_error` are things like

* Tracking and notifying authentication errors that may be tied to things like stale OAuth tokens, or revoked permissions, that might require manual intervention.
* For roots scoped to a particular resource, detecting when that resource may be in a bad state that breaks multiple endpoints, and notifying or taking actions to put the resource back in a good state

Note, instead of `on_alchemrest_error` you may also want to consider using tools like `enable_response_capture` or `Alchemrest.on_result_rescued`. Here are some example use cases, and a suggestion of which of these tools is the best fit for each

* You want to log response bodies as part of your error management system. Use `enable_response_capture` on your `Alchemrest::Request` classes and then set up `Alchemrest.on_response_captured` to route to your error management system. See [Capturing Responses For Debugging](./capturing_responses_for_debugging.md)
* You want to make sure that you see the underlying error even if you use `unwrap_or_rescue`. Use `Alchemrest.on_result_rescued`.
* You want to send a slack message to a specific team when the API they interact with has a 400 error. Use `on_alchemrest_error` on the root class managed by that team.
