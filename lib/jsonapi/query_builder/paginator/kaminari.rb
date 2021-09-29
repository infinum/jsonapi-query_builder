# frozen_string_literal: true

require "kaminari"

module Jsonapi
  module QueryBuilder
    module Paginator
      class Kaminari < BasePaginator
        def paginate(page_params)
          paged_collection = collection
            .page(page_params[:number])
            .per(page_params[:size])
            .padding(page_params[:offset])

          [paged_collection, pagination_details(paged_collection, page_params)]
        end

        private

        def pagination_details(collection, page_params)
          {
            number: collection.current_page,
            size: collection.limit_value,
            offset: page_params[:offset],
            total: collection.total_count,
            total_pages: collection.total_pages,
            next_page: collection.next_page,
            prev_page: collection.prev_page
          }
        end
      end
    end
  end
end
