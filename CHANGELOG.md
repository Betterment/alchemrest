# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project aims to adhere to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added <!-- for new features. -->

### Changed <!-- for changes in existing functionality. -->

### Deprecated <!-- for soon-to-be removed features. -->

### Removed <!-- for now removed features. -->

### Fixed <!-- for any bug fixes. -->

## [3.1.1] - 2025-10-30

### Changed

- Updated documentation to improve guidance for both Claude Code and human developers

## [3.1.0] - 2025-09-08

### Removed

- Dropped support for Rails 7.1 - minimum version is now Rails 7.2

## [3.0.0] - 2025-08-21

### Added

- Support for HTTP 204 No Content responses with `allow_empty_response` option on requests
- Time zone support for chainable transforms - now requires explicit timezone specification when parsing ISO strings

### Changed

- Time transforms now require explicit timezone specification to avoid hidden assumptions
- Kill switches and circuit breakers are now opt-out instead of opt-in for better default reliability

### Removed

- All deprecated `Alchemrest::Root` syntax for `define_request`
- Deprecated initialization syntax for kill switches and circuit breakers
- Support for GET requests with body using `def body` (use `endpoint` macro with query params instead)
- Moved `Alchemrest::Sentry` plugin to separate `alchemrest-sentry` gem to reduce dependencies
- `s.time` transform removed and replaced with chainable transforms like `s.from.string.to(Time).using(:local)`

### Breaking Changes

- Chainable time transforms now require timezone parameter: `s.from.string.to(Time).using(:local)`
- Sentry integration now requires separate `alchemrest-sentry` gem
- Old `define_request` syntax no longer supported
- GET requests can no longer define body method for query params

## [2.26.0]

### Added

- Seperate `url.values=` and `url.query=` methods to control querystring vs url templates for a request endpoint 
- `url.encode_query_with=` to allow developers to control how the query string is encoded (:rack vs :form)

### Deprecated 

- `url.params=` which allowed setting both the query string and url template values at the same time.

## [2.25.2] 2025-04-24

### Fixed

- Type signatures

## [2.25.1] 2025-04-23

### Fixed

- Ensured introspection api properly supports contraints on array and maybe transforms by moving constraints to output type

## [2.25.0] 2025-04-11

### Added

- Complete public introspection api, including documentation

## [2.23.1] 2025-01-06

### Added

- Fix bug with request type signature
- Ensure custom cops are visible

## [2.19.0] 2025-01-06

### Added

Sorbet type signatures

## [2.18.1] - 2025-01-16

### Removed

Uncruft as a runtime dependency.

## [2.18.0] 2025-01-06

### Added

New block style method calls for `Alchemrest::Request#define_request`. Now you can and should call define_request like this

```
define_request :get_users, GetUsers do |request|
  request.defaults = { id: @id }
end
```

This provides better sorbet support, and also gives us more flexibility to change request initialization behavior later

### Deprecated

Calling `define_request` with the old syntax

## [2.17.0] 2024-12-17

### Added

New block style method calls for `Alchemrest::Request#endpoint`. Now you can and should call endpoint like this

```
endpoint :get, 'api/v1/users/:id' do |url|
  url.params = { id: @id }
end
```

This provides better sorbet support, and also gives us more flexibility to change url building behavior later

### Deprecated

Calling endpoint with the old syntax

## [2.16.0] 2024-08-08

- Add configurable identifier method to `Alchemrest:;Request` class, and update `Alchemrest::RespnseCaptured::Handler` to consume the request's `#identifier` method instead of building it.

## [2.15.0] 2024-07-31

- Change how the sentry integration works so we can capture multiple responses for the same request

## [2.14.1] 2024-07-22

- Restore behavior of GET requests with `def body` putting the body in url params, but mark as deprecated

## [2.14.0] 2024-07-16

- Expands the `Alchemrest::Data::Graph` with `sub_graphs` (same as `children` but more clear naming) and `fields`
- Expands the `Alchemrest::Data::Graph` with new `fields` which is a hash of `Alchemrest::Data::Field` types
- Adds `Alchemrest::Data::Field` which has reference to a transform instance, a provided name, and marking to indicate if it is required
  - Schema builds and adds fields to the graph objects, using the `required` and `optional` values defined
  - Field will automatically override provided required value with false if transform type is a `Morpher::Transform::Maybe`
- `Alchemrest::Data::CaptureConfiguration` remains unchanged in behavior, leveraging `Alchemrest::Data::Graph#sub_graphs` to maintain current functionality but make code more clear

## [2.13.0] 2024-07-12

- Add inteface to customize existing response pipelines by appending and inserting steps

## [2.12.1] 2024-07-11

- Expose the `Alchemrest::Client` configuration at the instance level to support overriding when client instances need to be initialized with dynamic data.

## [2.12.0] 2024-05-29

- Add tool to observe errors at the root level

## [2.11.0] 2024-05-13

- Add deprecation notice for implicit kill switch configuration

## [2.10.0] 2024-05-01

- Make kill switch configuration match circuit breaker configuration
- Set default service name based on urls

## [2.9.1] 2024-05-02

- Bugfix, return correct left_hand-side error during MorpherTransformError in Data::Schema#from_hash

## [2.9.0] 2024-04-30

- Make circuit breaker configuration more customizable and streamlined
- Refactor circuit breaker internals to rely on `Alchemrest::Result` classes
- Stop surfacing Faraday errors, and make all request related errors be `Alchemrest::Error`
  subclasses

## [2.8.0] 2024-04-25

- Add numerical constraints to chainable transforms syntax

## [2.7.5] 2024-03-26

- Improve DX for response capture to encourage better resiliency.

## [2.6.5] 2024-03-22

- Improve circuit breaker support, fixing bugs with test setup and allow override failure definition in `Alchemrest::Response` subclasses

## [2.5.5] 2024-03-19

- Bugfix, allow delete requests with bodies

## [2.5.4] 2024-03-07

- Bugfix, accidental extra require

## [2.5.3] 2024-02-05

### Added

- Client configuration option to remove `Alchemrest::FaradayMiddleware::UnderScoreResponse` as default response
- Better configuration of default logger when running in a rails environment, to silence noisy test output
- Options to set request headers in `Alchemrest::Request` classes by overriding `def headers`

## [2.5.2] 2023-12-15

### Removed

- Dropped support for Ruby <3.2

## [2.5.1] 2023-12-06

### Fixed

- Remove accidental require of `pg` gem from kill switch adapters

## [2.5.0] 2023-12-01

### Added

- `Alchemrest::FaradayMiddleware::KillSwitch` as additional opt-in
  middleware under `use_kill_switch` flag upon configuration. This
  provides a counterpart to circuit breakers that is functionally
  equivalent to manuallly opening and closing the circuit.

### Removed

- Dropped support for Rails <7 and Ruby <3.2

## [2.4.5] 2023-10-31 🎃

### Fixed

- Bug with sentry response capture unable to capture non hash data
- Bug with load order for sentry middleware that prevented users from working with hash data when using circuit breakers
- Bug with response capture logging full response bodies and potentially leaking data

## [2.4.4] 2023-10-19

### Fixed

Bug with error case for `Alchemrest::Data.from_hash`

## [2.4.3] 2023-10-17

### Added

Modify the `Alchemrest::Sentry` capture code to include a tag so we can quickly find all Sentry errors that include a captured response. This is mostly to help us monitor how response capture is working generally

## [2.4.2] 2023-10-16

### Fixed

Handle other conditional for breaking change from 2.4.0

## [2.4.1] 2023-10-16

### Fixed

Accidental breaking change in 2.4.0 for use cases where the implementor has a custom response class that overrides `Alchemrest::Response#data` to drill down into the body

## [2.4.0] 2023-10-12

### Added

Optional `path_to_payload` arg for `Alchemrest::Request.returns` to allow better support for nested payloads in requests

## [2.3.0] 2023-10-11

### Added

- `Circuitbox::FaradayMiddleware` as additional opt-in middleware under `use_circuit_breaker` flag upon configuration. This mimicks the setup of how we are currently using circuitbox outside of alchemrest.

## [2.2.0] 2023-09-22

### Fixed

- Bug with alchemrest factories where any nested child 3 levels down was nil

### Added

- Alchemrest::FactoryBot::OmitKey to support building objects with optional keys (vs nullable values)
- The `configure_response_capture` method on `Alchemrest::Data` to allow control over what data is captured
- The `Sanitize` and `Omit` transforms to provide very flexible ways to customize what data is captured on a per request basis.

## [2.1.1] 2023-09-13

### Fixed

- Bugs with the sentry response capture plugin that were preventing it from working

## [2.1.0] 2023-09-12

### Added

- `Alchemrest::FactoryBot.enable!` to allow control over when the factorybot integration is loaded, ensuring we don't try to set it up before factorybot is loaded

## [2.0.1] 2023-09-12

### Added

- Bugfix to ensure that roots using inheritence still work with the new `request_defintion` structure

## [2.0.0] 2023-09-12

### Removed

- Previously deprecated `Alchemrest::Request.transform_with` and `Alchemrest::Request.response_transformer` methods.
- Previously deprecated %{} interpolation style definition of paths using the `Alchemrest::Request.endpoint` macro. Now all paths must be specified using rails route syntax, via mustermann

### Added

- New response capture framework which allows developers to log/capture raw response bodies for analysis and debugging.
- New tools for improved testing of alchemrest integrations include FactoryBot and webmock extensions
- Documentation on how to write tests around code that uses alchemrest

## [1.4.1] 2023-06-15

### Removed

- Rails 6.0.x support. Minimum version is now 6.1

## [1.4.0] 2023-06-15

### Changed

- `unwrap_or_rescue` can rescue more classes of exceptions, not just `Alchemrest::Error`. The list of rescuable exceptions can be configured via `Alchemrest.rescuable_exceptions=`
- By default, `unwrap_or_rescue` will now also rescue farday timeout errors, ssl errors, and other kinds of farday connection failures `[Faraday::TimeoutError, Faraday::SSLError, Faraday::ConnectionFailed]`

### Removed

- Ruby 2.7.x support. Minimum version is now 3.0

## [1.3.0] 2023-06-09

### Changed

- Roots can define `#client` instead of using `.use_client`
- Requests can define `#response_transformer` instead of using `.returns` or `.transform_with`

### Deprecated

- `Request.response_transformer`
- `Request.transform_with`

## [1.2.0] 2023-05-03

### Changed

Changed how we configure client connections to support lazy connection setup

## [1.1.1] 2023-04-21

### Fixed

- Remove customized Warning.warn behavior that conflicts with some warning/deprecation libraries (eg. Uncruft). This was slated to be removed post Ruby >3.0.0 upgrades.

- Uncruft support

## [1.1.0] 2023-04-17

### Added

- introduce a new `#date` transform method that allows you to transform dates. You can use this to transform any iso8601 valid string (ie '2022-01-01') into a date object.

  Example

```ruby
class DateExample < Alchemrest::Data
  schema do |s|
    {
      required: {
        start_on: s.date,
      },
    }
  end
end
```

## [1.0.0] 2023-04-13

### Added

- Simplified connection handling by providing a default configuration for clients that inherit from Alchemrest::Client. This update keeps the ability for users to customize configuration, but makes set-up more straightforward for most use-cases.
- Added deprecation warning for build_connection
- Eagerly initializing @connection with `Alchemrest::Client#configure_faraday_connection` vs. lazy initialization w/ `Alchemrest::Client#build_connection`

Now you can do:

```ruby
class Client < Alchemrest::Client
  # Default configuration
  configure_faraday_connection(url: "https://my.api.com/")
end
```

Instead of:

```ruby
class Client < Alchemrest::Client
  def self.build_connection
    @connection ||= Faraday.new(url: url, headers: headers) do |c| # rubocop:disable Naming/MemoizedInstanceVariableName
      c.request :json
      c.use Alchemrest::FaradayMiddleware::UnderScoreResponse
      c.use Alchemrest::FaradayMiddleware::JsonParser
      c.use Alchemrest::FaradayMiddleware::ExternalApiInstrumentation, external_service: 'hubspot'
      c.adapter Faraday.default_adapter
      c.options[:open_timeout] = 4
      c.options[:timeout] = 10
    end
  end
end
```

## [1.0.0.pre4] 2023-03-24

### Added

- Syntatic sugar for defining requests that return collections
  Previously we had to do

```ruby
transform_with MyData::TRANSFORM.array
```

Now you can do

```ruby
returns MyData[]
```

This also allows us to deprecate `transform_with` since it covers most scenarios where you'd want to use a custom transformation. In the rare circumstance where it's necssary, implementors can still override `Request#response_transformer`.

## [1.0.0.pre3] 2023-03-14

### Added

- Update `allow_additional_properties` default value from `false` to `true`

## [0.1.1] 2022-09-08

### Added

- New time transforms that can be used in data models like

```ruby
schema do |s|
  {
    required: {
      completed_at: s.time(:iso),
    },
  }
end
```

Supports iso time, epoch in seconds, and epoch in milliseconds

## [0.1.0] 2022-07-26

### Added

- Initial release!
