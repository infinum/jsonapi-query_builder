# frozen_string_literal: true

require "jsonapi/query_builder/mixins/sort"

module Jsonapi
  module QueryBuilder
    class BaseQuery
      include Mixins::Sort

      attr_reader :collection, :params

      def initialize(collection, params)
        @collection = collection
        @params = params
      end

      def results
        sort collection
      end
    end
  end
end
