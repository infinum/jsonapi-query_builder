# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Paginator
      class BasePaginator
        attr_reader :collection

        # @param [ActiveRecord::Relation] collection
        def initialize(collection)
          @collection = collection
        end

        # @param [Hash] page_params
        # @return [[ActiveRecord::Relation, Hash]] Records and pagination details
        def paginate(page_params)
          raise NotImplementedError, "#{self.class} should implement ##{__method__}"
        end
      end
    end
  end
end
