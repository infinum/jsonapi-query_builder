# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    class BaseFilter
      attr_reader :collection, :query

      def initialize(collection, query)
        @collection = collection
        @query = query
      end

      def results
        raise NotImplementedError, "#{self.class} should implement #results"
      end
    end
  end
end
