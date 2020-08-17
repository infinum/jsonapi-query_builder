# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Filtering
        extend ActiveSupport::Concern

        class_methods do
          def supported_filters
            @supported_filters || {}
          end

          def filters_by(attribute, filter = nil, **options)
            filter ||= ->(collection, query) { collection.where(attribute => query) }
            @supported_filters = {**supported_filters, attribute => [filter, options]}
          end
        end

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
