# Writing Tests

AlchemREST is designed to support good testability at every level of your integration. In this document we'll cover key techniques for testing various pieces of your API integrations.

## Testing Data Classes

There are two things you may want to test when it comes to your custom data classes. First, you probably want to test that the `schema` block you've defined, and the transformations you've set up build your records appropriately. Second, you'll want to test that the custom methods you've added on top of these classes return the data you expect in a variety of situations.

In both cases, we strongly recommend that you use the method `.from_hash` to build up your object and all its children. This method will construct the entirety of your object graph from a Ruby hash, running transformations etc. This most closely mimics how objects will get built up in the HTTP request/response lifecycle. Given the our bank API examples used throughout this documentation, this will look something like this.

```ruby
transaction = BankApi::Data::Transaction.from_hash(
  amount_cents: 120_00,
  status: "completed",
  settled_at: "2023-10-10T00:00:00",
  description: "check transaction",
  source: {
    source_type: "check",
    check_number: 100,
    check_image_back_url: "#{BankApi::Client::API_URL}/api/v1/check_images/100/back.png",
    check_image_front_url: "#{BankApi::Client::API_URL}/api/v1/check_images/100/front.png",
  },
)
```

However, over time you may start to see some pain points with this strategy. Because of AlchemREST's strict response parsing rules, you may find yourself having to update all your test files any time you add a new required field to your schema. This is because any tests like the above which use the old schema will start failing since they don't have the new required field.

As a result, you probably want to have some way to centralize building out your test response data. There are a number of strategies you can use to do this, including yaml files of "fixtures", dedicated methods.

However, the approach we recommended is actually to use `FactoryBot`. You may be familiar with `FactoryBot` for constructing `ActiveRecord` records for your tests, but it's actually flexible enough to support non `ActiveRecord` classes as well. We've provided a few `FactoryBot` extensions in AlchemREST, allowing you to create factories for your data classes relatively easily. Let's make a factory for our `BankApi::Data::Transaction` example above

```ruby
alchemrest_factory :bank_api_transaction, class: 'BankApi::Data::Transaction' do 
  amount_cents { 120_00 }
  status { "completed" }
  settled_at { "2023-10-10T00:00:00" }
  description { "check transaction"}
  source: { alchemrest_hash_for(:bank_api_check) }
end

# We also need a factory for the nested source object

alchemrest_factory :bank_api_check, class: 'BankApi::Data::Check' do 
  source_type { "check" }
  check_number { 100 }
  check_image_back_url {"#{BankApi::Client::API_URL}/api/v1/check_images/100/back.png" }
  check_image_front_url {"#{BankApi::Client::API_URL}/api/v1/check_images/100/front.png" }
end

FactoryBot.alchemrest_record_for(:bank_api_transaction, description: "My Special Transaction")
```

You can see 3 new methods, `alchemrest_factory`, `alchemrest_record_for`, and `alchemrest_hash_for`. The first `alchemrest_factory`, is what you use to register your factory, instead of the default `factory` method. The second `alchemrest_record_for` is what you use to build an instance of an AlchemREST record, and its full object graph, the third `alchemrest_hash_for` is what you use for nested objects, or when you just want to create a hash, rather than a full object

Behind the scenes, `alchemrest_record_for` is basically building up a giant hash, just like you'd get back from the real API, and then passing that hash into `Bank::Api::Data::Transaction.from_hash`, just like AlchemREST does when processing an API response. As a result you get factory objects that closely mirror the real thing.

AlchemREST factories are just normal factorybot factories under the hood, so you can use them as you're used to, with traits, etc. For example let's say you want a trait `from_ach` to have ach transactions vs check transactions. Then we might have this.

```ruby
alchemrest_factory :bank_api_transaction, class: 'BankApi::Data::Transaction' do 
  amount_cents { 120_00 }
  status { "completed" }
  settled_at { "2023-10-10T00:00:00" }
  description { "check transaction"}
  source: { alchemrest_hash_for(:bank_api_check) }
  
  trait :from_ach do 
    source: { alchemrest_hash_for(:bank_api_ach) }
  end
end

# We also need factories for the nested source objects

alchemerst_factory :bank_api_check, class: 'BankApi::Data::Check' do 
  source_type { "check" }
  check_number { 100 }
  check_image_back_url {"#{BankApi::Client::API_URL}/api/v1/check_images/100/back.png" }
  check_image_front_url {"#{BankApi::Client::API_URL}/api/v1/check_images/100/front.png" }
end

alchemrest_factory :bank_api_ach, class: 'BankApi::Data::Ach' do 
  source_type { "ach" }
  trace_number { '12354689' }
end

FactoryBot.alchemrest_record_for(:bank_api_transaction, :from_ach, description: "My Special ACH Transaction")
```

Similarly to how it's done above, you can compose together factory results using a combination of `alchemrest_record_for` at the top level, and `alchemrest_hash_for` nested records.

```ruby
FactoryBot.alchemrest_record_for(
  :bank_api_transaction, 
  source: FactoryBot.alchemrest_hash_for(:bank_api_ach, trace_number: "111111"),
  description: "My Special ACH Transaction"
)
```

The last special thing we need with AlchemREST factories, is a way to handle optional keys. An optional key is different from a `nil` value, so we need a way to clearly indicate that we want to leave a key out completely, or AlchemREST will not properly parse the hash. To handle this we provide `Alchemrest::FactoryBot::OmitKey.instance`. To use this, you simply provide it as a value to the factory as so.

```ruby
Alchemrest::FactoryBot.alchemrest_record_for(
  :bank_api_transaction, 
  source: Alchemrest::FactoryBot::OmitKey.instance
)
```

This will result in a record that's initialized like this, where `source` is absent entirely

```ruby
BankApi::Data::Transaction.from_hash(
  {
    amount_cents: 10_000,
    status: :completed,
    settled_at: '2020-01-01T01:30:00.000-05:00',
    description: 'Test',
  }
)
```

With these sorts of factories, if your API response changes to include a new required field, you can quickly update all your tests just by updating the relevant factory.

To use these factorybot extensions you'll need to call `Alchemrest::FactoryBot.enable!` before FactoryBot loads your factory definitions.

## Testing Request Classes

In general there are 3 things you may want to test with your request classes.

* The `path` is setup correctly
* The `body` is setup correctly (for a post request)
* You can actually successfully execute a request

The first two items are fairly easy, you can just new up instances of your request class and directly test those methods.

For the third test, you can use tools like `webmock` or `webvalve` to stub out your API endpoints and then call something like.

```ruby
request =  stub_request(:get, "#{api_url}/api/v1/users/1")
          .to_return(body: { name: "Jamie", age: 22 }.to_json)
          
response = BankApi::Client.new.build_http_request(BankApi::Requests::GetUser.new(id: 1)).execute!
expect(response.ok?).to be_truthy
expect(request).to have_been_requested
```

## Testing Roots

On your root, you likely don't need to test simple methods defined by `define_request`, although you can if you want to. Instead, you'll get the highest impact if you focus your tests on the custom methods you add to the root that wrap or chain various request methods.

Generally we recommend when testing a root, you should test things with a fully HTTP request/response lifecycle, using tools like `webmock` and `webvalve` to fake the HTTP communication.

To help out with this, we ship AlchemREST with some helpers that can quickly stub out endpoints using `webmock` using your already defined request classes.

Specifically this looks like writing code like this.

```ruby
 before do
   root = BankApi::Root.new(id: user_id)
   stub_alchemrest_request(root.build_request(:get_user))
        .to_return(
          status: 200,
          body: FactoryBot.alchemrest_hash_for(:bank_api_user).to_json,
        )
  end
```

There are two items worth nothing here. First is `Root#build_request` which gives you a way to get an instance of a request class from a root without executing it. Second is `stub_alchemrest_request` which takes an `Alchemrest::Request` instance, and automatically stubs out an endpoint that matches the path of the request. `build_request(:get_user)` can take the same params that you'd pass to the method `get_user` would take.

The second `stub_alchemrest_request` is just a thin wrapper around the webmock method `stub_request`. It uses the request instance to calculate the right path and HTTP method to stub, and then returns the stub object. From there you can chain additional webmock methods off of it, like `to_return` to fully control the response.

`stub_alchemrest_request` also takes two optional arguments `with_request_body: true|false` and `with_headers: true|false`. If you pass `true` to either of these, then the wrapper will also call `.with(body: request.body)` or `.with(headers: request.headers)` accordingly, ensuring your stub will only respond to requests that exactly match the body and/or headers of the request instance you passed into `stub_alchemrest_request`

Lastly you'll see we have another `FactoryBot` helper here, the method `alchemrest_hash_for`. This provides a way for you to quickly build up a valid AlchemREST hash from your existing factories. This helps address the same problems that the `alchemrest_record_for` method addresses when testing your data.

To use these new helpers you'll need to include this in your `RSpec.configure` block

```ruby
RSpec.configure do |config|
  config.include Alchemrest::WebmockHelpers
end
```

## Testing Application Code

The last aspect of this worth considering is how to test your application code that consumes your AlchemREST API integration. This is always a complex question, and different organizations may have different styles of testing that they prefer, but generally, we recommend that you make use of mocks and stubs when testing AlchemREST code.

Particularly, we suggest that you stub out your root class, and use the `FactoryBot` patterns described earlier to build out instances of your data class to be returned by your root class. If you use rspec, you can do this easily with code like

```ruby
before do 
  root_double = instance_double(
    BankApi::Root, 
    all_transactions: FactoryBot.build_list(:bank_api_transaction, 10)
  )
  allow(BankApi::Root).to receive(:new).and_return(root_double)
end
```

That allows you to avoid setting up lots of HTTP endpoint mocks, and control the behavior of your API layer very straightforwardly.
