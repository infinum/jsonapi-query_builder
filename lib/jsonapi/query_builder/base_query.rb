# frozen_string_literal: true

require "jsonapi/query_builder/mixins/include"
require "jsonapi/query_builder/mixins/paginate"
require "jsonapi/query_builder/mixins/sort"

module Jsonapi
  module QueryBuilder
    class BaseQuery
      include Mixins::Include
      include Mixins::Paginate
      include Mixins::Sort

      attr_reader :collection, :params

      def initialize(collection, params)
        @collection = collection
        @params = params
      end

      def results
        collection
          .tap(&method(:sort))
          .tap(&method(:add_includes))
          .tap(&method(:paginate))
      end
    end
  end
end
