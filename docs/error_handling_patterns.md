# Error Handling Patterns

One of the key drivers behind AlchemREST is establishing good patterns around API errors. In this section of the docs, we'll go over how to build a robust error handling system using AlchemREST.

You probably want to read [Working with Results](./working_with_results.md) first, to get a good sense of the basic error handling techniques we'll walk through in this document.

## Welcome to Bank.com

To walk through these patterns, we'll imagine we're integrating with the fictional bank.com/api and walk through how we might iteratively build up a robust integration with this third party system. We're focusing on just the error handling pieces here, so we won't show the full AlchemREST setup, but this example is based on the example used for our [iteration tests found here](../spec/dummy/bank_api). You can also see these same examples in our [error handling integration test](../spec/integration/error_handling.rb). Our first order of business is to write some code that will let us get a user by id from this API. We'll define a request and add a method to our root so we can call code like this

```ruby
result = BankApi::Root.new(id: 1234).get_user
```

We'll also configure `Alchemrest` so that unexpected API errors show up in our sentry alerts, even if we rescue them. We do that by writing an initializer which calls this code

```ruby
Alchemrest.on_result_rescued { |e| Sentry.capture_exception(e) }
```

Somewhere in our calling code, we want to get a list of the users accounts, which is exposed via `BankApi::Data::User#accounts`

For our first iteration, this just looks like

```ruby
accounts = BankApi::Root.new.get_user.unwrap_or_rescue { [] }
```

With this, accounts will either by the list of accounts, if our API request succeeds on an empty array if it errors. Additionally if it errors, we'll also get a message in Sentry

## Our first error

During beta testing, we discover that if someone has not yet set up an account, the bank.com/api returns a 404 error code. Our code gracefully handles this by returning an empty array, but we want to be able to show a custom UI in this case prompting them to sign up. Also, we'd like to stop getting 404 alerts in Sentry, even though our code is running fine. So now we rewrite our code to this

```ruby
result = BankApi::Root.new(id: 1234).get_user
accounts, not_found = case result
                        in Alchemrest::Result::Ok(user)
                          [user.accounts, false]
                        in Alchemrest::Result::Error({status: 404})
                          [nil, true]
                        else
                          result.unwrap_or_rescue { [[], false] }
                      end
```

Now here's how our code will behave.

1. If the requests success, `accounts` will have the users accounts and `not_found` will be false
2. If the request fails with 404, we'll make `accounts` nil, and set `not_found` to true.
3. If the request errors for any other reason, we'll set `accounts` to an empty array, and `not_found` to false, and we'll get an alert in Sentry.

## Extracting information from errors

Now let's imagine we're dealing with a different endpoint. Now we're trying to call `POST bank.com/api/user/:id/accounts/:id/transactions`. We've setup our request and root so we can call `BankApi::Root.new(id: 1234).post_transaction(account_id: 4, amount: 1000)`

We setup our calling code like the below

```ruby
result = BankApi::Root.new(id: 1234).post_transaction(account_id: 4, amount: 1000)
result.unwrap_or_raise!
```

Here, we chose to `raise` rather than the rescue, because there's no good recovery path if this mutative action fails. However, we can still introduce more iterative error handling paths as we learn more about this API. For example, let's say we realize that the API returns a 422 error code in case there is an account lock. Additionally, this response has a body that looks like

```ruby
{
  errors: { code: "001", description: "account_locked" }
}
```

If we want to handle that code specially, we can do the following.

### Setup our client to extract the errors

First we need to instruct AlchemREST on how to extract error information from a response body. We can do this buy creating our own `Alchemrest::Response` class like this

```ruby
class BankApi::Client < Alchemrest::Client
  # existing client setup ...

  def build_response(raw_response)
    Response.new(raw_response)
  end

  class Response < Alchemrest::Response
    def error_details
      body.fetch("errors", {}).symbolize_keys
    end
  end
end
```

Once we do this, we can write pattern matching code like this

```ruby
result = BankApi::Root.new(id: 1234).post_transaction(account_id: 4, amount: 1000)
status = case result
           in Alchemrest::Result::Ok(response)
             :success
           in Alchemrest::Result::Error({status: 422, error: { code: "001" }})
             :locked
           else
             result.unwrap_or_raise!
         end
```

Now if the account is locked, we won't raise, we'll just set status to `:locked`, and then we can write code in our UI to show a special locked experience

## Dealing with unexpected data

Now lets imagine that Bank.com adds some new fraud management features to their system. Previously, user accounts could be in two states: "open" and "locked". Let's imagine they introduce a new account state "frozen", where users can put their own freeze on an account if they think it's been compromised.

Unfortunately, they don't tell you about these new features, they just release it and now your code is getting users accounts with this new state you didn't expect. What happens now?

First, let's look at our code for the user object today

```ruby
module BankApi
  module Data
    class User < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            status: s.enum(%w(open locked)),
          },
        }
      end
    end
  end
end
```

You can see it's a simple object with a name and a status field with 2 possible values, "open" and "locked". Since "frozen" is not one of those values, AlchemREST will not transform the api response to a `BankApi::Data::User` object. The idea is your downstream code is probably not prepared to handle this new state anyways, so we shouldn't just pass it through.

So what happens instead? Well let's look at our calling code again.

```ruby
result = BankApi::Root.new(id: 1234).get_user
accounts, not_found = case result
                        in Alchemrest::Result::Ok(user)
                          [user.accounts, false]
                        in Alchemrest::Result::Error({status: 404})
                          [nil, true]
                        else
                          result.unwrap_or_rescue { [[], false] }
                      end
```

This bad data means the `result` object is an instance of `Alchemrest::Result::Error`, but it's not
one of the ones that we handle because it doesn't match the second pattern statement. Instead, we fall through to `unwrap_or_rescue` and return an empty array.

The good news is you'll still see the original error in your exception management system. It will look something like this

```shell
Alchemrest::MorpherTransformError: Response does not match expected schema: - Morpher::Transform::Sequence/2/Alchemrest::Data::Transforms::LooseHash/[:status]/Alchemrest::Data::Transforms::Enum: Expected: enum value from ["open", "locked"] but got: "frozen
```

This message tells you that the underlying library we use for data transformation, Morpher, couldn't transform the data because it expected the value of the `[:status]` field to be "open" or "locked". You can reach out to Bank.com and ask them about this new, unexpected status and then decide what to do.

## General Principles

Now that we've walked through some common error handling examples, let try to call out some good principles we can use to build robust API integrations

* Start out by using a simple `unwrap_or_rescue` or `unwrap_or_raise`, depending on whether or not you're dealing with mutative vs non-mutative actions. For non-mutative prefer `unwrap_or_rescue`, so you can provide a reasonable fallback behavior if an API is fully down.
* As you learn more about your third party API, use pattern matching to begin to handle known error responses. This will allow your code to behave more flexibly, and silence unnecessary alerting from expected failure conditions.
* Always make sure you have comprehensive error handling by keep an `else` case in your pattern matching, where you continue to invoke the appropriate `unwrap_*` fallback method
* Generally, you shouldn't try to handle Morpher transformation errors via pattern matching. Let them fall through to your else case, and then adjust your underlying data definitions to handle the data the API actually returns
