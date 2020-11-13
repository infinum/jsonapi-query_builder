# frozen_string_literal: true

require "jsonapi/query_builder/mixins/sort/param"

module Jsonapi
  module QueryBuilder
    module Mixins
      module Sort
        extend ActiveSupport::Concern

        UnpermittedSortParameters = Class.new ArgumentError

        class_methods do
          attr_reader :_default_sort

          def _unique_sort_attributes
            @_unique_sort_attributes || [id: :asc]
          end

          def supported_sorts
            @supported_sorts || {}
          end

          def unique_sort_attributes(*attributes)
            @_unique_sort_attributes = attributes
          end

          alias_method :unique_sort_attribute, :unique_sort_attributes

          def default_sort(options)
            @_default_sort = options
          end

          def sorts_by(attribute, sort = nil)
            sort ||= ->(collection, direction) { collection.order(attribute => direction) }
            @supported_sorts = {**supported_sorts, attribute => sort}
          end
        end

        def sort(collection, sort_params = send(:sort_params))
          sort_params = Param.deserialize_params(sort_params)
          ensure_permitted_sort_params!(sort_params) if sort_params

          collection
            .yield_self { |c| add_order_attributes(c, sort_params) }
            .yield_self(&method(:add_unique_order_attributes))
        end

        private

        def sort_params
          params[:sort]
        end

        def ensure_permitted_sort_params!(sort_params)
          unpermitted_parameters = sort_params.map(&:attribute).map(&:to_sym) - self.class.supported_sorts.keys
          return if unpermitted_parameters.size.zero?

          raise UnpermittedSortParameters, [
            unpermitted_parameters.to_sentence,
            unpermitted_parameters.count == 1 ? "is not a" : "are not",
            "permitted sort attribute".pluralize(unpermitted_parameters.count)
          ].join(" ")
        end

        def add_order_attributes(collection, sort_params)
          return collection if self.class._default_sort.nil? && sort_params.blank?
          return collection.order(self.class._default_sort) if sort_params.blank?

          sort_params.reduce(collection) do |sorted_collection, sort_param|
            sort = self.class.supported_sorts.fetch(sort_param.attribute.to_sym)

            if sort.respond_to?(:call)
              sort.call(sorted_collection, sort_param.direction)
            else
              sort.new(sorted_collection, sort_param.direction).results
            end
          end
        end

        def add_unique_order_attributes(collection)
          collection.order(*self.class._unique_sort_attributes)
        end
      end
    end
  end
end
