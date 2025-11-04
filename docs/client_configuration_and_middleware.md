# Client Configuration and Middleware

Under the hood, AlchemREST uses Faraday for the raw HTTP communication layer. Faraday is a highly flexible and customizable HTTP client. A key part of this customization is the idea of middleware, which uses the same model and rack middleware to allow you to customize your response handling.

Alchemrest ships with a few default pieces of middleware that are automatically added to your client when you use the default setup. Specifically these are

## Alchemrest::FaradayMiddleware::JsonParser

This middleware takes the body of a response and transforms it into a hash with string keys using `MultiJson`. If the body is not parseable, it will transform the body into an empty hash. **Note we probably want to change this behavior and make this become another kind of error that can bubble up through the typical AlchemREST result chain**

## Alchemrest::FaradayMiddleware::UnderScoreResponse

This middleware takes the hash created by the json parser and converts any keys in that hash that are camel cased, into a snake cased form (ie `userName` => `user_name`). This ensures our properties on our data models look more rubyish. (ie `user.user_name` vs `user.userName`)

Note that this response is enabled by default unless you set:

```ruby
config.underscore_response_body_keys = false
```

## Alchemrest::FaradayMiddleware::ExternalApiInstrumentation

This middleware ensures that every single outbound API call for your client is wrapped in a call to `::ActiveSupport::Notifications.instrument`. This passes in the entire Faraday env into the instrumentation pipeline, with the event name of `#{external_service}_api_request` where `external_service` is the service name provided by setting `config.service_name = "my_service"` in your client configuration. You can then write subscribers that extract the request status code, url, duration, etc and log or track it as needed. Note for this middleware to be included you do need to call `config.service_name = "my_service"`.

## Alchemrest::FaradayMiddleware::KillSwitch

This middleware enables the [kill switch feature defined here](./working_with_kill_switches_and_circuit_breakers.md).

Note for this middleware to be included you do need to set:

```ruby
config.service_name = "my_service"
config.use_kill_switch = true
```

And, you need to have properly configured a kill switch adapter. The
ActiveRecord adapter is the default and preferred adapter. To configure
it, you must run

```shell
bundle exec rails generate alchemrest:kill_switch_migration
bundle exec rails db:migrate
```

## Additional Configuration

You can set up a circuit breaker for the third party API, so that if the API is down, you'll stop trying to hit it. Under the hood this uses the [circuitbox gem](https://github.com/yammer/circuitbox). To enable the circuit breaker call the following in your config block

```ruby
config.service_name = "my_service"
config.use_circuit_breaker(true)
```

Additionally to disable the circuit in a test context you can use

```ruby
config.use_circuit_breaker(disabled_when: -> { Rails.env.test? })
```

replacing `Rails.env.test?` with whatever code evaluates to true in your testing context.

For more details see [Working with Kill Switches and Circuit Breakers](./working_with_kill_switches_and_circuit_breakers.md)

## Configuring the client

The default setup of the client looks like this

```ruby
class Client < Alchemrest::Client
  configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
  end
end
```

With this you get a Faraday connection with all the middleware listed above, hitting the url `https://my.api.com`

If you want to make additional configuration changes to the Faraday connection, you can call `config.connection.customize`.

```ruby
class Client < Alchemrest::Client
 configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
    config.use_circuit_breaker = true
    config.connection.customize do |c|
      c.options[:open_timeout] = 4
      c.options[:timeout] = 10
    end
  end
end
```

The `customize` method takes a block which receives the Faraday connection object you can write the same code you would for a block passed into `Farday.new { |c| ... }`. Note though that we've already set up some of the connection options for you, specifically.

```ruby
  c.request :json
  c.response :json
  c.adapter Faraday.default_adapter
  c.use <middleware> # Built in middleware described above
```

If you don't want to include the built in middleware you can call `customize(use_default_middleware: false)`. We'll still set up the request, response, and adapter options for you though.
