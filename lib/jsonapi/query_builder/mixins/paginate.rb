# frozen_string_literal: true

require 'jsonapi/query_builder/pagination_strategy/pagy'

module Jsonapi
  module QueryBuilder
    module Mixins
      module Paginate
        # Paginates the collection and returns the requested page. Also sets the pagination details that can be used for
        # displaying metadata in the Json:Api response.
        # @param [ActiveRecord::Relation] collection
        # @return [ActiveRecord::Relation] Paged collection
        def paginate(collection)
          pagination_strategy.paginate(collection)
        end

        def pagination_details
          pagination_strategy.pagination_details
        end

        private

        def pagination_strategy
          @pagination_strategy ||= pagination_strategy_class.new(params: params)
        end

        def pagination_strategy_class
          if defined?(Pagy)
            Jsonapi::QueryBuilder::PaginationStrategy::Pagy
          end
        end
      end
    end
  end
end
