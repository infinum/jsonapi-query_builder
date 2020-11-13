# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    class BaseSort
      attr_reader :collection, :direction

      def initialize(collection, direction)
        @collection = collection
        @direction = direction
      end

      def results
        raise NotImplementedError, "#{self.class} should implement #results"
      end
    end
  end
end
