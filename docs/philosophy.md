# Philosophy

AlchemREST's design is influenced by principles we've developed at Betterment over years of working with 3rd party APIs. These principles first showed up as common patterns and practices in our code base, before we pulled them out into this library. In this document we try to outline those principles and show how they're embodied in our design

## Keep it Class-y

We prefer to model API responses as classes which wrap the data, rather than trying to work with raw hashes. With a class, you can add new methods that transform the data in interesting ways, alias field names to ones that are more meaningful in your domain, etc. This is why AlchemREST includes the concept of `Data` models, which wrap the response data.

## Use read only models

We prefer that our API response data models be read only, rather than `ActiveRecord` style objects that expose methods to mutate the data. Unlike databases, most APIs aren't consistent in making every endpoint handle both reads and updates simply by switching the relevant HTTP method. Often endpoints are readonly, or you need to perform mutations on separate RPC style endpoints.

## Failure is an "Option"

The very nature of HTTP APIs is that they are often quite unreliable. Any code that interacts with them needs to treat failure as a highly likely scenario, and developers should be prompted to handle failure by default. The concept of a monadic "Option" style class, borrowed from languages like Rust, is a highly effective way to do this. This is how our `Alchemrest::Result` class is modeled, and why we ensure every operation returns an `Alchemrest::Result` by default.

## Keep your API calls "Rooted"

We prefer API access to happen through method chains "rooted" at your local domain models, and then moving to a dedicated API object. (like `user.api.accounts`). This serves a handful of useful purposes.

* It makes it easy for engineers to decide where to locate new API code, just decide which domain model it's related to, and attach it to that domain models "root"
* It supports easy trust root chaining i.e. `current_user.billing_api.get_bills`.
* It makes it easy to share API parameter data between related calls.

## Requests as Classes not methods

We prefer modelling requests as classes that can be built and executed as two separate steps, rather than a standalone method. This supports better testability and better readability for requests that have complex bodies.

## Write code against the interface you want, not the one you have

In general, we believe that you should avoid making your domain code be constrained by the choices of a third party API designer. Your goal should be to expose an interface to your calling code that supports your domain needs, and abstracts the API implementation details as much as possible. This is another feature of the "root" concept, because your "root" class offers a good place to...

* Chain requests, and expose those chains as methods that domain code can call
* Cache results for improved performance
* Alias methods to better fit your domain

## Trust no data

We prefer strictly parsing API responses and fail fast and loud when your expectations aren’t met. This is a means to hold our partners accountable and find out about issues early before they have significant downstream impacts (think the Van Halen M&M test).

## Best Practices Built In

We believe that every API integration should ship with best practices built in without developers having to set up and configure them. This means circuit breakers and kill switches to deal with API outages and easy to manage debugging tools to give better insight into API responses,
