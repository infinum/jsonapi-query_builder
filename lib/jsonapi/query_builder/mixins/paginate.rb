# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Paginate
        extend ActiveSupport::Concern

        class_methods do
          # Sets the paginator used to page the results. Defaults to Pagy
          #
          # @param [Jsonapi::QueryBuilder::Paginator::BasePaginator] paginator A subclass of BasePaginator
          def paginator(paginator)
            @paginator = paginator
          end

          def _paginator
            @paginator || Paginator::Pagy
          end
        end

        attr_reader :pagination_details

        # Paginates the collection and returns the requested page. Also sets the pagination details that can be used for
        # displaying metadata in the Json:Api response.
        # @param [ActiveRecord::Relation] collection
        # @param [Object] page_params Optional explicit pagination params
        # @return [ActiveRecord::Relation] Paged collection
        def paginate(collection, page_params = send(:page_params))
          records, @pagination_details = self.class._paginator.new(collection).paginate(page_params)

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
