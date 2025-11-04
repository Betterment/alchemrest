# AlchemREST Documentation

## Getting Started

- [**Anatomy of an AlchemREST Integration**](./anatomy_of_an_alchemrest_integration.md) - A comprehensive walkthrough of all components in an AlchemREST integration, from clients and requests to data models and roots.

- [**Philosophy**](./philosophy.md) - Core design principles behind AlchemREST, including class-based models, failure handling, and trust-root chaining.

- [**Writing Tests**](./writing_tests.md) - Best practices for testing data classes, requests, and roots using FactoryBot integration and WebMock helpers.

## Core Concepts

- [**Working with Results**](./working_with_results.md) - Learn how to use `Alchemrest::Result::Ok` and `Alchemrest::Result::Error` to handle API responses with unwrapping, pattern matching, and chaining.

- [**Working with Data**](./working_with_data.md) - Complete guide to creating and using `Alchemrest::Data` classes with schemas, transformations, nested objects, and time handling.

- [**Error Handling Patterns**](./error_handling_patterns.md) - Strategies for building robust error handling using pattern matching, custom response classes, and handling unexpected data.

## Advanced Features

- [**Client Configuration and Middleware**](./client_configuration_and_middleware.md) - Configure Faraday connections, built-in middleware (JSON parsing, instrumentation), circuit breakers, and kill switches.

- [**Response Pipelines**](./response_pipelines.md) - Customize how raw HTTP responses are transformed into domain objects using the pipeline architecture with modular transformation steps.

- [**Custom Transformations**](./custom_transformations.md) - Create custom Morpher transformations for validating and converting API data beyond the built-in helpers.

- [**Chainable Transforms**](./chainable_transforms.md) - Build complex validation and transformation pipelines using the `from.where.to` syntax for strings and numbers.

- [**Advanced Pattern Matching**](./advanced_pattern_matching.md) - Deep dive into how pattern matching works in AlchemREST, including `deconstruct` implementations and customization strategies.

## Reliability & Debugging

- [**Working with Kill Switches and Circuit Breakers**](./working_with_kill_switches_and_circuit_breakers.md) - Configure proactive kill switches and reactive circuit breakers to handle API outages and unreliable services.

- [**Capturing Responses for Debugging**](./capturing_responses_for_debugging.md) - Enable response capture to persist API responses for debugging, with configurable sanitization and filtering.

## Tooling

- [**Introspection**](./introspection.md) - Use the introspection API to programmatically inspect data class schemas, fields, types, and constraints for documentation or tooling.

## Architecture

- [**Architecture of AlchemREST**](./architecture-of-alchemrest.md) - Technical overview of AlchemREST internals, including the request processing flow, Faraday integration, and response pipeline architecture.
