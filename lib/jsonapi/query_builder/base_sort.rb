# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    class BaseSort
      attr_reader :collection, :direction

      # @param [ActiveRecord::Relation] collection
      # @param [Symbol] direction of the ordering, one of :asc or :desc
      def initialize(collection, direction)
        @collection = collection
        @direction = direction
      end

      # @return [ActiveRecord::Relation] Collection with order applied
      def results
        raise NotImplementedError, "#{self.class} should implement #results"
      end
    end
  end
end
