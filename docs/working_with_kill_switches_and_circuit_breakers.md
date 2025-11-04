# Working with Kill Switches and Circuit Breakers

In AlchemREST, kill switches are how we proactively disable a client's
ability to make requests until we chose to reenabled them and circuit
breakers are how our system detects that the remote system is in a bad
state and we should stop making requests to it.

These features work in concert to provide a rich resiliency toolkit for
HTTP integrations implemented using AlchemREST.

## Kill Switches vs Circuit Breakers

The distinction between kill switches and circuit breakers is simple. A
kill switch is a proactive control and a circuit breaker is a reactive
one.

Circuit breakers observe the results of requests to determine
heuristically if a service is unreliable or "down" enough to skip
even attempting subsequent requests for a period. Eventually the circuit
will attempt another request (or a few) to check and see if the service
is still unhealthy and if not it will close the circuit and start over.

Kill switches on the other hand are a hard, operator-controlled toggle.
Once you flip the switch on, it stops sending requests until you flip it
off.

Kill switches come in handy when we need to disable an integration that
is violating our expectations or behaving in an unsafe way that might
not trip the circuit breaker, or at least not do so reliably.

In this scenario, you can flip the switch on, work to resolve the
underlying issue, and then flip it off. All while the app is running; no
need for a deployment or an app restart.

They are also useful when we know that a service will be unavailable for
a significant period and we want to avoid the latency and clumsiness of
relying on circuit breakers to heuristically detect the outage and stay
open the whole time. This is much rarer, but it's sometimes seen with
integrations that flap back and forth between healthy and unhealthy.

## Enabling Kill Switches and Circuit Breakers

Both kill switches and circuit breakers are enabled via the client configuration
process like so

```ruby
class SomeClient < Alchemrest::Client
  configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
    config.use_kill_switch = true
    config.use_circuit_breaker(true)
  end
end
```

This ensures your API client can use these two features. For more details on configuration
options check out [Client Configuration and Middleware](./client_configuration_and_middleware.md)

## Working with Kill Switches

### Toggling a Kill Switch

Activating a kill switch for a specific client is simple:

```ruby
SomeClient.kill_switch.activate!
```

In this example, `SomeClient` is a class that extends from
`Alchemrest::Client` and configures a `service_name` for itself.

Once the kill switch is activated, requests will automatically short
circuit before being made, returning an `Alchemrest::Result::Error`.

Flipping the switch off is equally simple:

```ruby
SomeClient.kill_switch.deactivate!
```

### Kill Switch Implementation considerations

Kill Switches are intended to be per `Alchemrest::Client`, but notably
the key that defines the scope of the switch is derived from the
`service_name` configured on a given client. Technically, this means
that if two clients share a service_name, they will both be controlled
by the same underlying kill switch. It's unlikely that you want that. If
you have a different Client, you probably also want a separate circuit
breaker and kill switch, so you will want a unique `service_name`.

## Working with Circuit Breakers

### Configuring your circuit breaker

To configure a circuit breaker you can pass configuration options into the `use_circuit_breaker` method like so

```ruby
class SomeClient < Alchemrest::Client
  configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
    config.use_kill_switch = true
    config.use_circuit_breaker(
      sleep_window: 60,
      time_window: 30,
      volume_threshold: 3,
      error_threshold: 50,
      disabled_when: -> { Rails.env.test? }
    )
  end
end
```

These options will be passed directly into `Alchemrest::CircuitBreaker.new`. The options are as follows

* `time_window`: The length of interval in seconds over which we calculate the error rate
* `volume_threshold`: The number of requests we have to see in the `time_window` before we calculate an error rate
* `error_threshold`: The rate value at which the circuit will open.
* `sleep_window`: The number of seconds the circuit stays open once we pass the error threshold
* `disabled_when`: a block that is evaluated to determine if we want the circuit breaker to be active or turned off

So for example the configuration above means that if we see 50% of the requests we make in a 30 second window fail,
we'll open the circuit for 60 seconds, and we must make at least 3 requests in a window before we check our failure
rate. And we'll never use the circuit breaker at all in our test environment. Note you can only provide some of the
options like

```ruby
class SomeClient < Alchemrest::Client
  configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
    config.use_kill_switch(true)
    config.use_circuit_breaker(disabled_when: -> { Rails.env.test? })
  end
end
```

In that case, the remaining options will be set to their defaults. Additionally you can use only the defaults with

```ruby
class SomeClient < Alchemrest::Client
  configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
    config.use_kill_switch(true)
    config.use_circuit_breaker(true)
  end
end
```

To disable a circuit breaker completely, you can simply call

```ruby
class SomeClient < Alchemrest::Client
  configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
    config.use_kill_switch(true)
    config.use_circuit_breaker(false)
  end
```

### Control what counts as a "failure"

A core part of circuit breakers is being able to categorize requests in to
failures and successes. A circuit opens when the ratio of failure to success
crosses a certain threshold. Out of the box, we consider HTTP timeouts, and
server errors as "failures". All other errors (ie 4XX codes) are not considered
failures from a circuit breaker perspective.

If this behavior isn't appropriate for a given API, you can control it by subclassing
`Alchemrest::CircuitBreaker` and overriding the `request_failed?` method. This method
receives an `Alchemrest::Request` and should return `true` if you want to consider the
request a failure.

Once you've subclassed `Alchemrest::CircuitBreaker` you can use your own breaker like this.

```ruby
class SomeClient < Alchemrest::Client
  configure do |config|
    config.service_name = "my_service"
    config.connection.url = "https://my.api.com/"
    config.use_kill_switch(true)
    config.use_circuit_breaker(MyCiruitBreaker.new(service_name: "my_service"))
  end
```

### What happens when a circuit is open

When the circuit breaker detects enough failures to trigger the "open" condition, then all requests made using that particular `Alchemrest::Client` instance will return an `Alchemrest::Result:Error` instance which wraps an `Alchemrest::CircuitOpenError`. Like any other result instances you can pattern match on this particular error class to handle circuit errors specifically, or just continue using `unwrap_and_raise!` or `unwrap_and_rescue {}` to handle them alongside other errors
