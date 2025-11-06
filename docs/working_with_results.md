# Working with Results

In AlchemREST, results are how we provide a flexible interface that lets you handle API errors, both client side and server side in a straightforward manner. The basic idea is that any AlchemREST operation that depends on an API wraps the response from that API in either an `Alchemrest::Result::Ok` or an `Alchemrest::Result::Error`. Developers can perform transformations on the result without unwrapping it, and then, when they are finally read for the raw value, they can use one of a handful of different unwrapping operations to determine if they've got a valid result, or an error, and handle it accordingly.

## Unwrapping Results

The easiest way to unwrap results is via the `unwrap_or_rescue` and `unwrap_or_raise!` methods. Both the `Alchemrest::Result::Error` and `Alchemrest::Result::Ok` classes support these methods.

* `uwrap_or_rescue` lets you provide a block which will be executed if the result is an error, allowing your code to fail gracefully.
* `unwrap_or_raise!` is the unsafe equivalent, which will give you the object inside the result wrapper, or raise if it's an error.

These two methods are great for simple scenarios, but if you need to handle different kinds of errors differently, then you'll want to reach for the next tool, pattern matching

### Pattern matching

Pattern matching is a new feature of the Ruby language, introduced as experimental in Ruby 2.7. The pattern matching syntax stabilized without any changes by Ruby 3.1, so we've chosen to make it a core part of the AlchemREST library. For a generalized overview of pattern matching see [An Introduction to Pattern Matching in Ruby](https://blog.appsignal.com/2021/07/28/introduction-to-pattern-matching-in-ruby.html). We'll do a quick crash course as it relates to AlchemREST here.

The basic idea behind pattern matching in Ruby is that it looks like a case statement on steroids. So for example, to take different actions depending on whether our result is an error or a success, we can do this

```ruby
result = api_root.get_user(1)
case result
  in Alchemrest::Result::Ok
    # do success stuff
  in Alchemrest::Result::Error
    # do failure stuff
end
```

What if we need access to the underlying data for our success case though? Well in that case we can do

```ruby
result = api_root.get_user(1)
case result
  in Alchemrest::Result::Ok(user)
    puts user.name
    # do success stuff
  in Alchemrest::Result::Error
    # do failure stuff
end
```

Here Ruby takes the object that is inside the `Ok` wrapper, and assigns it to the variable `user`, so now we can access that data inside our success case.

Similarly for errors we can do

```ruby
result = api_root.get_user(1)
case result
  in Alchemrest::Result::Ok(user)
    puts user.name
    # do success stuff
  in Alchemrest::Result::Error(error)
    puts error.response.status
    # do failure stuff
end
```

Here error is always an instance of `Alchemrest::Error` which gives you access to the raw response.

When it comes to errors though, we can go even farther, and pattern match down to the HTTP status code like this

```ruby
result = api_root.get_user(1)
case result
  in Alchemrest::Result::Ok(user)
    puts user.name
    # do success stuff
  in Alchemrest::Result::Error({status: 400})
    # Do X
  in Alchemrest::Result::Error({status: 401})
    # Do Y
  in Alchemrest::Result::Error({status: 503})
    raise "uh oh"
    # do failure stuff
end
```

If you create a custom `Alchemrest::Response` class, you can go even farther, and pattern match on the details of the error itself. First create a new class something like this

```ruby
MyApiResponse < Alchemrest::Response
  def error_details
    data[:error][:msg]
  end
end
```

The error details method should pull the error data out of the actual HTTP response and return a string that contains whatever error data you want to be able to match on. Next modify your client to use your custom response class

```ruby
class Aggregation::Ascensus::Api::Client < Alchemrest::Client
  configure do |config|
    config.connection.url = url
    config.connection.headers = headers
    config.service_name = "ascensus"
  end

  def build_response(raw_response)
    MyApiResponse.new(raw_response)
  end
end
```

Now you can write code like

```ruby
result = api_root.post_new_user_enrollment(enrollment_params)
case result
  in Alchemrest::Result::Ok(user)
    puts user.name
    # do success stuff
  in Alchemrest::Result::Error({status: 400, error: "User already exists"})
    # Do X
  in Alchemrest::Result::Error({status: 400, error: "Invalid phone number"})
    # Do Y
  in Alchemrest::Result::Error({status: 503})
    raise "uh oh"
    # do failure stuff
end
```

Note error details doesn't even have to be a string, it could be a hash for more complex scenarios, which would allow for even more complex matching in the case of multiple errors on a single response

For even more customization around pattern matching, see the [Advanced Pattern Matching](./advanced_pattern_matching.md)

### Chaining Results with the `Alchemrest::Result.for`

Sometimes the only reason you want to unwrap a result is to use it in another request. Maybe you want to even chain together 2 or 3 requests before really unwrapping and accessing the final value.

In that case, the method `Alchemrest::Result.for` is the right choice. This let's you write code like

```ruby
result = Alchemrest::Result.for do |try|
  user = try.unwrap api_root.get_user(1)
  api_root.post_make_payment(account_id: user.accounts.first, amount: 1000)
end
```

If both requests succeed this will return an `Alchemrest::Result::Ok` wrapping the result of the second request. If the `get_user` request fails, this will short circuit execution and return an `Alchemrest::Result::Error`. If the `post_make_payment` request fails, then it will return an `Alchemresult::Result` error for that.

You can combine `Alchemrest::Result.for` and pattern matching for some very flexible request handling like this.

```ruby
result = Alchemrest::Result.for do |try|
  user = try.unwrap api_root.get_user(1)
  api_root.post_make_payment(account_id: user.accounts.first, amount: 1000)
end

case result
  in Alchemrest::Result::Error({status: 404, error: 'User doesn't exist'})
    # Do X
  in Alchemrest::Result::Error({status: 403, error: 'Insufficient funds in account'})
    # Do Y
  in Alchemrest::Result::Error({status: 500})
    # Do Z
end
```
