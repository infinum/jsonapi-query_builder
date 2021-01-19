# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    class BaseFilter
      attr_reader :collection, :query

      # @param [ActiveRecord::Relation] collection
      # @param [String] query the query value used for filtering
      def initialize(collection, query)
        @collection = collection
        @query = query
      end

      # @return [ActiveRecord::Relation] Collection with the filter applied
      def results
        raise NotImplementedError, "#{self.class} should implement #results"
      end
    end
  end
end
