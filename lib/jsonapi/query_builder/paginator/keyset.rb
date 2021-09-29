# frozen_string_literal: true

require "active_record"

module Jsonapi
  module QueryBuilder
    module Paginator
      class Keyset < BasePaginator
        DEFAULT_DIRECTION = :after
        DEFAULT_LIMIT = 25

        def paginate(page_params)
          page_params = extract_pagination_params(page_params)
          records = apply_pagination(collection, page_params)

          [records, page_params]
        end

        private

        def extract_pagination_params(params)
          {
            column: params.fetch(:column, nil),
            position: params.fetch(:position, nil),
            direction: params.fetch(:direction, DEFAULT_DIRECTION),
            limit: params.fetch(:limit, DEFAULT_LIMIT)
          }
        end

        def apply_pagination(collection, pagination_params)
          column = pagination_params[:column]
          position = pagination_params[:position]
          direction = pagination_params[:direction]
          limit = pagination_params[:limit]

          return collection unless column

          collection = apply_order(collection, column, direction)
          collection = collection.limit(limit.to_i)

          return collection unless position

          apply_filter(collection, column, position, direction)
        end

        def apply_order(collection, column, direction)
          if direction.to_sym == DEFAULT_DIRECTION
            collection.reorder(collection.arel_table[column].asc)
          else
            collection.reorder(collection.arel_table[column].desc)
          end
        end

        def apply_filter(collection, column, position, direction)
          if direction.to_sym == DEFAULT_DIRECTION
            collection.where(collection.arel_table[column].gt(position))
          else
            collection.where(collection.arel_table[column].lt(position))
          end
        end
      end
    end
  end
end
