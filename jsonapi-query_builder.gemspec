# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jsonapi/query_builder/version"

Gem::Specification.new do |spec|
  spec.name = "jsonapi-query_builder"
  spec.version = Jsonapi::QueryBuilder::VERSION
  spec.authors = ["Jure Cindro"]
  spec.email = ["jure.cindro@infinum.co"]

  spec.summary = "Support `json:api` querying with ease!"
  spec.description = <<~MD
    `Jsonapi::QueryBuilder` serves the purpose of adding the json api query related SQL conditions to the already scoped collection, usually used in controller index actions.

    With the query builder we can easily define logic for query filters, attributes by which we can sort, and delegate pagination parameters to the underlying paginator. Included relationships are automatically included via the `ActiveRecord::QueryMethods#includes`, to prevent N+1 query problems.
  MD
  spec.homepage = "https://github.com/infinum/jsonapi-query_builder"
  spec.license = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/infinum/jsonapi-query_builder"
    spec.metadata["changelog_uri"] = "https://github.com/infinum/jsonapi-query_builder/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.5"

  spec.add_runtime_dependency "activerecord", ">= 5", "<= 6.1"
  spec.add_runtime_dependency "pagy", "~> 3.5"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "super_diff"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "lefthook"
  spec.add_development_dependency "irb"
end
