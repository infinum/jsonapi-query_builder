# frozen_string_literal: true

# require 'kaminari'

module Jsonapi
  module QueryBuilder
    module Paginator
      class Kaminari
        def paginate(collection, params)
          page_params = extract_page_params(params)
          records = collection.page(page_params[:number])
            .per(page_params[:size])
            .padding(page_params[:offset])

          [records, pagination_details(records, page_params)]
        end

        private

        def extract_page_params(params)
          {number: 1, **params.fetch(:page, {})}
        end

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
