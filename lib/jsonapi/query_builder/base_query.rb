# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    class BaseQuery
      def initialize(collection, _params)
        @collection = collection
      end

      def results
        collection
      end

      private

      attr_reader :collection
    end
  end
end
