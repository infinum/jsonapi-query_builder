# frozen_string_literal: true

require "jsonapi/query_builder/mixins/include"
require "jsonapi/query_builder/mixins/sort"

module Jsonapi
  module QueryBuilder
    class BaseQuery
      include Mixins::Include
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
      end
    end
  end
end
