# frozen_string_literal: true

require "jsonapi/query_builder/mixins/filter"
require "jsonapi/query_builder/mixins/include"
require "jsonapi/query_builder/mixins/paginate"
require "jsonapi/query_builder/mixins/sort"

module Jsonapi
  module QueryBuilder
    class BaseQuery
      include Mixins::Filter
      include Mixins::Include
      include Mixins::Paginate
      include Mixins::Sort

      attr_accessor :collection, :params

      # @param [ActiveRecord::Relation] collection
      # @param [Hash] params Json:Api query parameters
      def initialize(collection, params)
        @collection = collection
        @params = params.deep_symbolize_keys
      end

      # @return [ActiveRecord::Relation] A collection with eager loaded relationships based on include params, filtered,
      #   ordered and lastly, paginated.
      # @note Pagination details are saved to an instance variable and can be accessed via the #pagination_details attribute reader
      def results
        collection
          .yield_self(&method(:add_includes))
          .yield_self(&method(:sort))
          .yield_self(&method(:filter))
          .yield_self(&method(:paginate))
      end

      # @param [integer, string] id
      # @return [Object]
      # @raise [ActiveRecord::RecordNotFound] if the record by the id is not found
      def find(id)
        find_by! id: id
      end

      # Finds the record by the id parameter the class is instantiated with
      # @return (see #find)
      # @raise (see #find)
      def record
        find_by! id: params[:id]
      end

      # @param [Hash] kwargs Attributes with required values
      # @return (see #find)
      # @raise [ActiveRecord::RecordNotFound] if the record by the arguments is not found
      def find_by!(**kwargs)
        add_includes(collection).find_by!(kwargs)
      end

      # Overribale hash that returns additional serializer options
      # @return [Hash]
      def serializer_options
        pagination_details
      end
    end
  end
end
