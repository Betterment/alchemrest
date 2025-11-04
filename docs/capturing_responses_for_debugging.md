# Capturing Responses For Debugging

One of the big challenges often inherent in working for third party API is debugging when the API responses you get back aren't what you expect. Oftentimes, when you need to inspect local data, your organization probably has some sort of tools for querying and exploring the database, so you inspect the local state of the application. However, similar tools for remote state in the API’s you work with aren't always available.

AlchemREST tries to help address this problem by offering a robust set of tools to capture response data as it's made by your application, and then persist it to a data store of your choice, so you can later inspect those outputs for debugging purposes. This document goes over how to setup and manage these response capture features

## Configuring where captured responses go

AlchemREST provides a flexible capture hook that you can write your own code into to persist responses anywhere you'd like. To do this, add these lines to your AlchemREST initializer.

```ruby
Alchemrest.on_response_captured do |identifier: result:|
  # Your persistence logic here
end
```

This block gets 2 arguments

* identifier - A string identifying the request endpoint, of a form like `PUT /api/v1/users`.
* result - An `Alchemrest::Result` object. This will be `Alchemrest::Result::Ok` if we were able to sanitize and process the capture data, and `Alchemrest::Result::Error` if something went wrong during the process.

If you don't set `Alchemrest.on_response_captured` any captured responses will just be written to `Alchemrest.logger`

## Configuring which responses are captured

By default, no responses are actually captured. Instead, you must opt your requests into being captured. To do this, you just need to override the method `response_capture_enabled` so it returns true

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
      end
      
      def response_capture_enabled
        true
      end
    end
  end
end
```

If you want to conditionally capture responses based on their properties, you can implement a body that checks for certain conditions and returns true and false accordingly.

If you want to capture response data in all cases you can use a short hand macro like this

```ruby
module BankApi
  module Requests
    class GetUser < Alchemrest::Request
      def initialize(id:) # rubocop:disable Lint/MissingSuper
        @id = id
      end

      returns BankApi::Data::User
      endpoint :get, '/api/v1/users/:id' do |url|
        url.values =  { id: @id } 
      end
      
      enable_response_capture
    end
  end
end
```

This is equilvalent to defining the method to always return true.

## Configuring what's captured

### Global Sanitization

By default AlchemREST captures the entire response body. This might include sensetive data like email addresses, social security numbers, etc. By default, AlchemREST will attempt to sanitize the response body, using the same framework that rails uses for parameter filtering in logs. You can configure what keys are filtered using `Alchemrest.filtered_parameters` like this.

```ruby
  Alchemrest.filtered_parameters += %i(account_number private_key account_id)
```

Much like with rails, the `filter_parameters` collection can be full key names, partial keys, or even blocks.

If you use AlchemREST within a Rails application, AlchemREST will actually copy the filter parameters from `Rails.application.config.filter_parameters`, ensuring that AlchemREST uses the same logic as Rails for your filtering.

### Configuration per data class

This global sanitization setup is good for ensuring general safety of the information sent through the response capture framework, but you may have reasons you need to customize the capture logic for certain kinds of API responses. AlchemREST provides a customization framework at a `Alchemrest::Data` class level that supports 2 operations.

* Opting out of sanitization for fields you know are safe, but still trigger your global sanitization rules
* Omitting fields that you are not interested in.

To do this, you can make use of the `configure_response_capture` macro on your `Alchemrest::Data` classes. You use that macro like this

```ruby
module BankApi
  module Data
    class Transaction < Alchemrest::Data
      schema do |s|
        # schema omitted for brevity
      end

      configure_response_capture do
        safe :account_id
        omitted :description
      end
    end
  end
end
```

So `configure_response_capture` takes a block. Within that block you can call the methods `safe` or `omitted` and pass them a list of symbols designating the keys that should be marked safe, or left out entirely.

Once you do this, any request which has response capture enabled, and returns this data class will be handled accordingly. Note that for nested classes, calling this method on the nested object will also ensure the nested paths are processed appropriately, no matter where in the object graph the data appears.

### Configuration per request

While the `Alchemrest::Data` class configuration hooks are probably good enough for most cases, we do have a more powerful customization hook that lives on the `Alchemrest::Request` class. Specifically, you can `Alchemrest::Request#capture_transformer`. By default this is implemented as

```ruby
def capture_transformer
  Alchemrest::Response::Pipeline.new(
    Alchemrest::Response::Pipeline::ExtractPayload.new,
    Alchemrest::Response::Pipeline::Sanitize.new,
  )
end
```

When you're using the above `Alchemrest::Data` class hooks we actually override this implementation and replace it with.

```ruby
def capture_transformer
  capture_configuration = domain_type.capture_configuration.with_path_to_payload(path_to_payload)

  Alchemrest::Response::Pipeline.new(
    Alchemrest::Response::Pipeline::ExtractPayload.new,
    Alchemrest::Response::Pipeline::Sanitize.new(
      safe: Alchemrest::HashPath.build_collection(capture_configuration.safe_paths),
    ),
    Alchemrest::Response::Pipeline::Omit.new(
      Alchemrest::HashPath.build_collection(capture_configuration.omitted_paths),
    ),
  )
end
```

So you can see how the simple configuration dsl rolls up into a powerful transformer.

For really complex customization needs, you can write your own implementation. It just needs to return an object that implements the `call(response)` method. This gives you a lot of flexibility to define your own objects, use a lambda, or anything else.

However, you're probably best off making use of Morpher, and particularly two transforms defined by `Alchemrest`. The first is what you see above, the `Alchemrest::Data::Transforms::Sanitize` transform. This is what's responsible for doing the parameter filtering described above. By default, it aggressively filters all out any of the items defined in `filter_parameters`, but if it's too aggressive, you can explicitly mark certain paths as safe, and opt them out of filtering. You can do this by passing the `safe` kwarg to `Sanitize.new` like this

```ruby
Alchemrest::Response::Pipeline::Sanitize.new(
  safe: Alchemrest::HashPath.build_collection(source: %i(check_number))
)
```

You can see that `Sanitize` takes an `Alchemrest::HashPath` instance, which is just a way of representing the path through a hash. This will create a `Sanitize` transform which leaves the path `source.check_number` untouched. So if you have an input like this

```ruby
    {
      amount_cents: 100_00,
      status: :completed,
      settled_at: '2020-01-01', 
      description: 'ice cream',
      source: {
        type: 'check',
        check_number: 12345,
        check_image_back_url: 'http://back.jpg',
        check_image_front_url: 'http://front.jpg',
      }
    }
```

the default output of `Sanitize.new.call(input)` would be

```ruby
   {
      amount_cents: 100_00,
      status: :completed,
      settled_at: '2020-01-01', 
      description: 'ice cream',
      source: {
        type: 'check',
        check_number: '[FILTERED]',
        check_image_back_url: 'http://back.jpg',
        check_image_front_url: 'http://front.jpg',
      }
    }
```

but with our custom transformation this would return.

```ruby
    {
      amount_cents: 100_00,
      status: :completed,
      settled_at: '2020-01-01', 
      description: 'ice cream',
      source: {
        type: 'check',
        check_number: 12345,
        check_image_back_url: 'http://back.jpg',
        check_image_front_url: 'http://front.jpg',
      }
    }
```

In addition to the `Sanitize` transform, `Alchemrest` also provides an `Omit` transform. This transform will drop pieces of the response that you're not interested in capturing. Much like `Sanitize` it takes in as a parameter a collection of `HashPath` objects that point to the nodes you want to remove. So using the same data as above, we can create an `Omit` transform like

```ruby
Alchemrest::Response::Pipeline::Omit.new(
  Alchemrest::HashPath.build_collection(source: %i(check_number))
)
```

This will result in an output that omits the entire `check_number` node like so

```ruby
    {
      amount_cents: 100_00,
      status: :completed,
      settled_at: '2020-01-01', 
      description: 'ice cream',
      source: {
        type: 'check',
        check_image_back_url: 'http://back.jpg',
        check_image_front_url: 'http://front.jpg',
      }
    }
```

You can chain these transforms together using a sequence transform like so

```ruby
  Morpher::Transform::Sequence.new(
    [
      Alchemrest::Response::Pipeline::Sanitize.new,
      Alchemrest::Response::Pipeline::Omit.new(Alchemrest::HashPath.build_collection(%i(description))
    ]
  )
```

then you can make this your requests response transformer.

```ruby
def capture_transformer
  Alchemrest::Response::Pipeline.new(
    Alchemrest::Response::Pipeline::Sanitize.new,
    Alchemrest::Response::Pipeline::Omit.new(Alchemrest::HashPath.build_collection(%i(description))
  )
end
```

### Creating safe capture pipelines

It's worth noting that you should be very intentional with how you implemented the block passed into `Alchemrest.on_response_captured`. If this block throws an error, it will halt the entire request execution process. As a result, we generally encourage the following strategies

* Put all "risky" code in the `Alchemrest::Response::Pipeline` you have for `capture_transformer`. If you have customized data processing logic that could fail, define a Morpher transformation with proper error handling, and insert it into the pipeline.
* Make use of pattern matching to unwrap the `Alchemrest::Result` object passed into your block.

### Overriding request identifiers

As part of the response capture features of AlchemREST, we provide a default configuration for identifying requests, using their 'http method' concatenating their 'path'.

```ruby
  def identifier
  "#{http_method} #{path}"
  end
```

However, for requests that may require a little more precise or refined identification, you can override the method `Alchemrest::Request#identifier`.

```ruby
  enable_response_capture

  def initialize(id)
    @id = id
  end

  def path
    "/v1/users#{@id}"
  end

  def http_method
    'get'
  end

  def identifier
    'This is a custom identifier'
  end
```

Inside of the custom `#identifier` method you can place any logic or method that returns a string to be consumed by the `Alchemrest::ResponseCapturedHandler` class. This gives you flexibility to adapt the identifiers for your organization or team's best practices.
