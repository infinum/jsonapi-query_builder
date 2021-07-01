# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Paginate
        attr_reader :pagination_details
        attr_accessor :paginator

        # Paginates the collection and returns the requested page. Also sets the pagination details that can be used for
        # displaying metadata in the Json:Api response.
        # @param [ActiveRecord::Relation] collection
        # @return [ActiveRecord::Relation] Paged collection
        def paginate(collection)
          records, @pagination_details = paginator.paginate collection, params

          records
        end
      end
    end
  end
end
