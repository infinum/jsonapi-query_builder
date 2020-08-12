# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Paginate
        include Pagy::Backend

        attr_reader :pagination_details

        def paginate(collection, params = send(:params))
          @pagination_details, records = pagy collection, page_params: :number,
                                                          items: params[:size],
                                                          outset: params[:offset]

          records
        end

        private

        def params
          @params[:page] || {}
        end
      end
    end
  end
end
