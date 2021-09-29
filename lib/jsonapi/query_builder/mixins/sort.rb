# frozen_string_literal: true

require "jsonapi/query_builder/mixins/sort/param"
require "jsonapi/query_builder/errors/unpermitted_sort_parameters"

module Jsonapi
  module QueryBuilder
    module Mixins
      module Sort
        extend ActiveSupport::Concern

        class_methods do
          attr_reader :_default_sort

          def _unique_sort_attributes
            @_unique_sort_attributes || [id: :asc]
          end

          def supported_sorts
            @supported_sorts || {}
          end

          # Ensures deterministic ordering. Defaults to :id in ascending direction.
          # @param [Array<Symbol, String, Hash>] attributes An array of attributes or a hash with the attribute and it's
          #   order direction.
          def unique_sort_attributes(*attributes)
            @_unique_sort_attributes = attributes
          end

          alias_method :unique_sort_attribute, :unique_sort_attributes

          # The :default_sort: can be set to sort by any field like `created_at` timestamp or similar. It is only used
          # if no sort parameter is set, unlike the `unique_sort_attribute` which is always appended as the last sort
          # attribute. The parameters are passed directly to the underlying active record relation, so the usual
          # ordering options are possible.
          # @param [Symbol, Hash] options A default sort attribute or a Hash with the attribute and it's order direction.
          def default_sort(options)
            @_default_sort = options
          end

          # Registers attribute that can be used for sorting. Sorting parameters are usually parsed from the `json:api`
          # sort query parameter in the order they are given.
          # @param [Symbol] attribute The "sortable" attribute
          # @param [proc, Class] sort A proc or a sort class, defaults to a simple order(attribute => direction)
          def sorts_by(attribute, sort = nil)
            sort ||= ->(collection, direction) { collection.order(attribute => direction) }
            @supported_sorts = {**supported_sorts, attribute => sort}
          end
        end

        # Sorts the passed relation with the default sort params (parsed from the queries params) or with explicitly
        # passed sort parameters.
        # Parses each sort parameter and looks for the sorting strategy for it, if the strategy responds to a call
        # method it calls it with the collection and parameter's parsed sort direction, otherwise it instantiates the
        # sort class with the collection and the parameter's parsed sort direction and calls for the results. Finally it
        # adds the unique sort attributes to enforce deterministic results. If sort params are blank, it adds the
        # default sort attributes before setting the unique sort attributes.
        # @param [ActiveRecord::Relation] collection
        # @param [Object] sort_params Optional explicit sort params
        # @return [ActiveRecord::Relation] Sorted relation
        # @raise [Jsonapi::QueryBuilder::Errors::UnpermittedSortParameters] if not all sort parameters are
        #   permitted
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

          raise Errors::UnpermittedSortParameters, unpermitted_parameters
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
