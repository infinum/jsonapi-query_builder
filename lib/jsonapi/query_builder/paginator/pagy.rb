# frozen_string_literal: true

require "pagy"
require "pagy/extras/items"

module Jsonapi
  module QueryBuilder
    module Paginator
      class Pagy < BasePaginator
        include ::Pagy::Backend

        def paginate(page_params)
          @params = {page: page_params}

          pagination_details, records = pagy collection, page: page_params[:number],
                                                         items: page_params[:size],
                                                         outset: page_params[:offset]
          [records, pagination_details]
        end

        private

        attr_reader :params
      end
    end
  end
end
