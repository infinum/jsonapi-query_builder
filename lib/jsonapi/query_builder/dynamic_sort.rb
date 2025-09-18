# frozen_string_literal: true

require "jsonapi/query_builder/base_sort"

module Jsonapi
  module QueryBuilder
    class DynamicSort < BaseSort
      attr_reader :dynamic_attribute

      # @param [ActiveRecord::Relation] collection
      # @param [Symbol] dynamic_attribute, which attribute to dynamically sort by
      # @param [Symbol] direction of the ordering, one of :asc or :desc
      def initialize(collection, dynamic_attribute, direction = :asc)
        super(collection, direction)
        @dynamic_attribute = dynamic_attribute
      end

      # @return [ActiveRecord::Relation] Collection with order applied
      def results
        raise NotImplementedError, "#{self.class} should implement #results"
      end
    end
  end
end
