# Jsonapi::Gem

`Jsonapi::Gem` bundles multiple `json:api` related responsibilities together. Gem's responsibilities include:
1. jsonapi request body parameter parsing

    This enables us to use strong params as we're used to, just like in any other rails application. Requests that have
    the `json_api` Mime type have their request body parameters parsed in a way according to the `json:api`
    specification.

2. jsonapi query support
    1. filters
    2. includes (to solve n+1 query problems when including relationships in index actions)
    3. sorting
    4. pagination
3. responders `json_api` responses
    1. serializes and renders CRUD controller actions with appropriate statuses
    2. serializes and renders errors if they are present
4. jsonapi response serialization
    1. including relationships
    2. response metadata generation
    3. error serialization
5. testing helpers
    1. request helpers
    2. response helpers
6. generators
    1. jsonapi query generator
    2. serializer generator that auto-populates attributes and relationships
    3. json schema generator that auto-populates attributes and relationships

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi-gem'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install jsonapi-gem

## Usage

### JsonApi::Query

```ruby
module Users
  class Query < JsonApi::Query
    ## sorting
    default_sort created_at: :desc
    sortable_by :first_name, :last_name, :email

    ## filtering
    filterable_by :first_name, :last_name
    filterable_by :email, ->(query) { where('email ilike ?', "%#{query}%") }
    filterable_by :type, TypeFilter
    filterable_by :mrn, MrnInMemoryFilter
  end
end

class UsersController < ApplicationController
  def index
    users_query = Users::Query.new(User, params.to_unsafe_hash)

    render json_api: users_query.results, status: :ok
  end
end
```

The query class is initialized using a collection and query parameters. Since query parameters are referenced explicitly
we can pass them as an unsafe hash. `JsonApi::Query` should not be responsible for scoping records based on current user
permissions, or for any other type of scoping. It's only responsibility is to support the `json:api` querying. Use
`pundit` or similar for policy scoping, custom query objects for other scoping, and then pass the scoped collection to
the `JsonApi::Query` object.

#### Sorting
##### Ensuring deterministic results
Sorting has a fallback to an unique attribute which defaults to the `id` attribute. This ensures deterministic paginated
collection responses. You can override the `unique_sort_attribute` in the query object. The parameters are passed
directly to the underlying active record relation, so the usual ordering options are possible.
```ruby
# set the unique sort attribute
unique_sort_attribute :email
# set the order direction
unique_sort_attribute email: :desc
# use compound order attributes
unique_sort_attribute created_at: :desc, email: :asc
````
##### Default sort options
The `default_sort` can be set to sort by a non-deterministic field like `created_at` timestamp or similar. It is only
used if no sort parameter is set, unlike the `unique_sort_attribute` which is always appended as the last sort
attribute. Same as with the former method, parameters are passed to the underlying active record relation.
```ruby
default_sort created_at: :desc
```
##### Enabling sorting for attributes
`sortable_by` denotes which attributes can be used for sorting. Sorting parameters are usually parsed from the
`json:api` sort query parameter in order they are given. So `sort=-first_name,email` would translate to
```ruby
{ first_name: :desc, email: :asc }
```

#### Filtering

##### Simple exact match filters
```ruby
filterable_by :first_name
# => collection.where(first_name: params.dig(:filter, :first_name)) if params.dig(:filter, :first_name).present?
```

##### Lambda as a filter
```ruby
filterable_by :email, ->(query) { where('email ilike ?', "%#{query}%") }
# => collection.where('email ilike ?', "%#{params.dig(:filter, :email)}%") if params.dig(:filter, :email).present?
```

##### Filter classes
But since we're devout followers of the SOLID principles, we can define a filter class that responds to `#call` method,
which returns the filtered collection results. Under the hood the filter class is initialized with the current scope and
the query parameter is passed to the call method. This is great if you're using query objects for ActiveRecord scopes,
you can easily use them to filter as well.
```ruby
filterable_by :type, TypeFilter
```
The filter class could look something like
```ruby
class TypeFilter < JsonApi::Filter
  def call(query)
    collection.where(type: query.split(','))
  end
end
```
Sometimes you need to perform in-memory filtering, for example when database attributes are encrypted. In that case,
those filters should be applied last, the order of definition in the query object matters.
```ruby
class MrnFilter < JsonApi::Filter
  def call(query)
    collection.select { |record| /#{query}/.match?(record.mrn) }
  end
end
```

##### Additional Options
You can override the filter query parameter name by passing the `query_parameter` option.
```ruby
filterable_by :first_name, query_parameter: 'name'
# => collection.where(first_name: params.dig(:filter, :name)) if params.dig(:filter, :name).present?
```
`allow_nil` option changes the filter conditional to allow explicit checks against if an attribute is null.
```ruby
filterable_by :first_name, allow_nil: true
# => collection.where(first_name: params.dig(:filter, :first_name)) if params[:filter]&.key?(:first_name)
```
`required` option raises an error if the filter parameter is not explicitly defined
```ruby
filterable_by :first_name, required: true
# => collection.where(first_name: params.fetch(:filter).fetch(:first_name))
```
The conditional when the filter is applied can also be defined explicitly. Note that these options override the
`allow_nil` option, as the condition if defined explicitly and you should handle `nil` explicitly as well.
```ruby
filterable_by :first_name, if: ->(query) { query.length >= 2 }
# => collection.where(first_name: params.dig(:filter, :first_name)) if params.dig(:filter, :first_name) >= 2
filterable_by :first_name, unless: ->(query) { query.length < 2 }
# => collection.where(first_name: params.dig(:filter, :first_name)) unless params.dig(:filter, :first_name) < 2
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/infinum/jsonapi-gem.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
