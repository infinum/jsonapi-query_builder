# frozen_string_literal: true

require "pagy"

module Jsonapi
  module QueryBuilder
    module Paginator
      class Pagy
        include ::Pagy::Backend

        attr_reader :params

        def paginate(collection, params)
          @params = params
          page_params = extract_page_params(params)

          details, records = pagy collection, page: page_params[:number],
                                              items: page_params[:size],
                                              outset: page_params[:offset]
          [records, details]
        end

        private

        def extract_page_params(params)
          {number: 1, **params.fetch(:page, {})}
        end
      end
    end
  end
end
