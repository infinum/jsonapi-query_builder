# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Paginate
        include Pagy::Backend

        attr_reader :pagination_details

        # Paginates the collection and returns the requested page. Also sets the pagination details that can be used for
        # displaying metadata in the Json:Api response.
        # @param [ActiveRecord::Relation] collection
        # @param [Object] page_params Optional explicit pagination params
        # @return [ActiveRecord::Relation] Paged collection
        def paginate(collection, page_params = send(:page_params))
          @pagination_details, records = pagy collection, page: page_params[:number],
                                                          items: page_params[:size],
                                                          outset: page_params[:offset]

          records
        end

        private

        def page_params
          {number: 1, **params.fetch(:page, {})}
        end
      end
    end
  end
end
