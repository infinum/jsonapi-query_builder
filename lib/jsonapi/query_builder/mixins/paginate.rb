# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Paginate
        include Pagy::Backend

        attr_reader :pagination_details

        def paginate(collection, page_params = send(:page_params))
          @pagination_details, records = pagy collection, page: page_params[:number],
                                                          items: page_params[:size],
                                                          outset: page_params[:offset]

          records
        end

        private

        def page_params
          {number: 1, **@params.fetch(:page, {}).symbolize_keys}
        end
      end
    end
  end
end
