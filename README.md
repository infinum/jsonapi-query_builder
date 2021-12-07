# Jsonapi::QueryBuilder ![lint](https://github.com/infinum/jsonapi-query_builder/workflows/lint/badge.svg)![spec](https://github.com/infinum/jsonapi-query_builder/workflows/spec/badge.svg)

`Jsonapi::QueryBuilder` serves the purpose of adding the json api query related SQL conditions to the already scoped
collection, usually used in controller index actions.

With the query builder we can easily define logic for query filters, attributes by which we can sort, and delegate
pagination parameters to the underlying paginator. Included relationships are automatically included via the
`ActiveRecord::QueryMethods#includes`, to prevent N+1 query problems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jsonapi-query_builder'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install jsonapi-query_builder

## Usage

```ruby
class UserQuery < Jsonapi::QueryBuilder::BaseQuery
  ## pagination 
  paginator Jsonapi::QueryBuilder::Paginator::Pagy # default paginator

  ## sorting
  default_sort created_at: :desc
  sorts_by :last_name
  sorts_by :first_name, ->(collection, direction) { collection.order(name: direction) }
  sorts_by :email, EmailSort

  ## filtering
  filters_by :first_name
  filters_by :last_name
  filters_by :email, ->(collection, query) { collection.where('email ilike ?', "%#{query}%") }
  filters_by :type, TypeFilter
  filters_by :mrn, MrnInMemoryFilter
end

class UsersController < ApplicationController
  def index
    user_query = UserQuery.new(User, params.to_unsafe_hash)

    render json: user_query.results, status: :ok
  end
end
```

The query class is initialized using a collection and query parameters. Since query parameters are referenced explicitly
we can pass them as an unsafe hash. `Jsonapi::QueryBuilder::BaseQuery` should not be responsible for scoping records
based on current user permissions, or for any other type of scoping. It's only responsibility is to support
the `json:api` querying. Use `pundit` or similar for policy scoping, custom query objects for other scoping, and then
pass the scoped collection to the `Jsonapi::QueryBuilder::BaseQuery` object.

### Pagination

Pagination support is configurable using the `paginator` method to define the paginator. It defaults to the `Pagy`
paginator, a lightweight and fast paginator. Other paginators currently supported are `Kaminari` and an implementation
of keyset pagination. Before using these paginators we need to explicitly require the gems in our Gemfile and the
paginator file in question. Additionally one can implement it's own paginator by inheriting
from `Jsonapi::QueryBuilder::Paginator::BasePaginator`. The minimum required implementation is a `#paginate` method that
receives page params and returns a page of the collection. It can return the pagination details as the second item of
the returned array, that can be used in the serializer for pagination metadata.

#### Using the Kaminari Paginator

```ruby
require "jsonapi/query_builder/paginator/kaminari"

paginator Jsonapi::QueryBuilder::Paginator::Kaminari
```

#### Using the Keyset Paginator

```ruby
require "jsonapi/query_builder/paginator/keyset"

paginator Jsonapi::QueryBuilder::Paginator::Keyset
```

### Sorting

#### Ensuring deterministic results

Sorting has a fallback to an unique attribute which defaults to the `id` attribute. This ensures deterministic paginated
collection responses. You can override the `unique_sort_attribute` in the query object.

```ruby
# set the unique sort attribute
unique_sort_attribute :email
# use compound unique sort attributes
unique_sort_attributes :created_at, :email
````

#### Default sort options

The `default_sort` can be set to sort by any field like `created_at` timestamp or similar. It is only used if no sort
parameter is set, unlike the `unique_sort_attribute` which is always appended as the last sort attribute. The parameters
are passed directly to the underlying active record relation, so the usual ordering options are possible. It is also
possible to define the default sort with a lambda or by passing a sort object.

```ruby
default_sort :created_at
# or
default_sort created_at: :desc
# or
default_sort ->(collection) { collection.order(created_at: :desc) }
# or
default_sort SortObject
```

#### Enabling simple sorting for attributes

`sorts_by` denotes which attributes can be used for sorting. Sorting parameters are usually parsed from the
`json:api` sort query parameter in the order they are given. So `sort=-first_name,email` would translate to
`{ first_name: :desc, email: :asc }`

```ruby
sorts_by :first_name
sorts_by :email
```

#### Sorting with lambdas

`sorts_by` also supports passing a lambda to implement a custom order or reorder function. The parameters passed to the
lamdba are collection and the direction of the order, which is either `:desc` or `:asc`.

```ruby
sorts_by :first_name, ->(collection, direction) { collection.order(name: direction) }
```

#### Sorting with sort classes

But since we're devout followers of the SOLID principles, we can define a sort class that responds to `#results` method,
which returns the sorted collection. Under the hood the sort class is initialized with the current scope and the
direction parameter.

### Filtering

#### Simple exact match filters

```ruby
filters_by :first_name
# => collection.where(first_name: params.dig(:filter, :first_name)) if params.dig(:filter, :first_name).present?
```

#### Lambda as a filter

```ruby
filters_by :email, ->(collection, query) { collection.where('email ilike ?', "%#{query}%") }
# => collection.where('email ilike ?', "%#{params.dig(:filter, :email)}%") if params.dig(:filter, :email).present?
```

#### Filter classes

We can define a filter class that responds to `#results` method, which returns the filtered collection results. Under
the hood the filter class is initialized with the current scope and the query parameter. However, if the object responds
to a `call` method it sends the current scope and the query parameter to that instead. This is great if you're using
query objects for ActiveRecord scopes, you can easily use them to filter with as well.

```ruby
filters_by :type, TypeFilter
```

The filter class could look something like

```ruby

class TypeFilter < Jsonapi::QueryBuilder::BaseFilter
  def results
    collection.where(type: query.split(','))
  end
end
```

Sometimes you need to perform in-memory filtering, for example when database attributes are encrypted. In that case,
those filters should be applied last, the order of definition in the query object matters.

```ruby

class MrnFilter < Jsonapi::QueryBuilder::BaseFilter
  def results
    collection.select { |record| /#{query}/.match?(record.mrn) }
  end
end
```

#### Additional Options

You can override the filter query parameter name by passing the `query_parameter` option.

```ruby
filters_by :first_name, query_parameter: 'name'
# => collection.where(first_name: params.dig(:filter, :name)) if params.dig(:filter, :name).present?
```

`allow_nil` option changes the filter conditional to allow explicit checks for an attribute null value.

```ruby
filters_by :first_name, allow_nil: true
# => collection.where(first_name: params.dig(:filter, :first_name)) if params[:filter]&.key?(:first_name)
```

The conditional when the filter is applied can also be defined explicitly. Note that these options override the
`allow_nil` option, as the condition if defined explicitly and you should handle `nil` explicitly as well.

```ruby
filters_by :first_name, if: ->(query) { query.length >= 2 }
# => collection.where(first_name: params.dig(:filter, :first_name)) if params.dig(:filter, :first_name) >= 2
filters_by :first_name, unless: ->(query) { query.length < 2 }
# => collection.where(first_name: params.dig(:filter, :first_name)) unless params.dig(:filter, :first_name) < 2
```

When you're using a filter class you can pass a symbol to the `:if` and `:unless` options which invokes the method on
the filter class.

```ruby
filters_by :type, TypeFilter, if: :correct_type?
# => type_filter = TypeFilter.new(collection, query); type_filter.results if type_filter.correct_type?
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

We're using `standardrb` and `lefthook`. You can install lefthook hooks via `lefthook install`. It will run linters and
standardrb checks before commits, and a bundle audit + whole spec suite before push.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `LEFTHOOK=0 bundle exec rake release`, which will create a git tag for the
version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/infinum/jsonapi-query_builder.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
