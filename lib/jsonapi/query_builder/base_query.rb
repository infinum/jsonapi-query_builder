# frozen_string_literal: true

require "jsonapi/query_builder/mixins/filtering"
require "jsonapi/query_builder/mixins/include"
require "jsonapi/query_builder/mixins/paginate"
require "jsonapi/query_builder/mixins/sort"

module Jsonapi
  module QueryBuilder
    class BaseQuery
      include Mixins::Filtering
      include Mixins::Include
      include Mixins::Paginate
      include Mixins::Sort

      attr_reader :collection, :params

      def initialize(collection, params)
        @collection = collection
        @params = params.deep_symbolize_keys
      end

      def results
        collection
          .yield_self(&method(:sort))
          .yield_self(&method(:add_includes))
          .yield_self(&method(:filter))
          .yield_self(&method(:paginate))
      end

      def find(id)
        find_by id: id
      end

      def record
        find_by id: params[:id]
      end

      def find_by(**kwargs)
        add_includes(collection).find_by(kwargs)
      end
    end
  end
end
