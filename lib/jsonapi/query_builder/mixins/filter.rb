# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Filter
        extend ActiveSupport::Concern

        class_methods do
          def supported_filters
            @supported_filters || {}
          end

          # Registers an attribute to filter by. Filters are applied in the order they are registered, if they are
          # applicable, so in-memory filters should be registered last.
          #
          # @param [Symbol] attribute The attribute which can be used to filter by
          # @param [proc, Class] filter A proc or a filter class, defaults to a simple where(attribute => query)
          # @param [Hash] options Additional filter options
          # @option options [Symbol] :query_parameter used to override the filter query parameter name
          # @option options [Boolean] :allow_nil changes the filter conditional to allow explicit checks for an
          #   attribute null value
          # @option options [proc, Symbol] :if Define the conditional for applying the filter. If passed a symbol, a
          #   method with that name is invoked on the instantiated filter object
          # @option options [proc, Symbol] :unless Define the conditional for applying the filter. If passed a symbol, a
          #   method with that name is invoked on the instantiated filter object
          #
          # @example Change the query parameter name
          #   filters_by :first_name, query_parameter: 'name'
          #   # => collection.where(first_name: params.dig(:filter, :name)) if params.dig(:filter, :name).present?
          #
          # @example Allow checks for null values
          #   filters_by :first_name, allow_nil: true
          #   # => collection.where(first_name: params.dig(:filter, :first_name)) if params[:filter]&.key?(:first_name)
          #
          # @example Change the filter condition
          #   filters_by :first_name, if: ->(query) { query.length >= 2 }
          #   # => collection.where(first_name: params.dig(:filter, :first_name)) if params.dig(:filter, :first_name) >= 2
          #   filters_by :first_name, unless: ->(query) { query.length < 2 }
          #   # => collection.where(first_name: params.dig(:filter, :first_name)) unless params.dig(:filter, :first_name) < 2
          #   filters_by :type, TypeFilter, if: :correct_type?
          #   # => TypeFilter.new(collection, query).yield_self { |filter| filter.results if filter.correct_type? }
          def filters_by(attribute, filter = nil, **options)
            filter ||= ->(collection, query) { collection.where(attribute => query) }
            @supported_filters = {**supported_filters, attribute => [filter, options]}
          end
        end

        # Filters the passed relation with the default filter params (parsed from the queries params) or with explicitly
        # passed filter parameters.
        # Iterates through registered filters so that the filter application order is settable from the backend side
        # instead of being dependent on the query order from the clients. If the filter condition for the filter
        # strategy is met, then the filter is applied to the collection. If the strategy responds to a call method it
        # calls it with the collection and parameter's parsed sort direction, otherwise it instantiates the filter class
        # with the collection and the parameter's query value and calls for the results.
        # @param [ActiveRecord::Relation] collection
        # @param [Object] filter_params Optional explicit filter params
        # @return [ActiveRecord::Relation, Array] An AR relation is returned unless filters need to resort to in-memory
        #   filtering strategy, then an array is returned.
        def filter(collection, filter_params = send(:filter_params))
          self.class.supported_filters.reduce(collection) do |filtered_collection, supported_filter|
            filter, options = serialize_filter(supported_filter, collection: filtered_collection, params: filter_params)

            next filtered_collection unless options[:conditions].all? { |type, condition|
              check_condition(condition, type, filter: filter, query: options[:query])
            }

            filter.respond_to?(:call) ? filter.call(filtered_collection, options[:query]) : filter.results
          end
        end

        private

        def filter_params
          params[:filter] || {}
        end

        def serialize_filter(supported_filter, collection:, params:)
          attribute, (filter, options) = *supported_filter

          options[:query_parameter] = options[:query_parameter]&.to_sym || attribute
          options[:query] = params[options[:query_parameter]].presence
          options[:conditions] = options.slice(:if, :unless).presence ||
            {if: options[:query].present? || options[:allow_nil] && params.key?(options[:query_parameter])}

          filter = filter.new(collection, options[:query]) unless filter.respond_to?(:call)

          [filter, options]
        end

        def check_condition(condition, type, **opts)
          (type == :if) == case condition
          when Proc
            condition.call(opts[:query])
          when Symbol
            opts[:filter].send(condition)
          else
            condition
          end
        end
      end
    end
  end
end
