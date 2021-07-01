# frozen_string_literal: true

require 'active_record'

module Jsonapi
  module QueryBuilder
    module Paginator
      class Keyset
        DEFAULT_DIRECTION = 'after'.freeze
        DEFAULT_LIMIT = 25

        def paginate(collection, params)
          pagination_params = extract_pagination_params(params)
          records = apply_pagination(collection, pagination_params)

          [records, pagination_params]
        end

        private

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

        def extract_pagination_params(params)
          page = params.fetch(:page, {})

          {
            column: page.fetch(:column, nil),
            position: page.fetch(:position, nil),
            direction: page.fetch(:direction, DEFAULT_DIRECTION),
            limit: page.fetch(:limit, DEFAULT_LIMIT)
          }
        end

        def apply_order(collection, column, direction)
          if direction == DEFAULT_DIRECTION
            collection.reorder(collection.arel_table[column].asc)
          else
            collection.reorder(collection.arel_table[column].desc)
          end
        end

        def apply_filter(collection, column, position, direction)
          if direction == DEFAULT_DIRECTION
            collection.where(collection.arel_table[column].gt(position))
          else
            collection.where(collection.arel_table[column].lt(position))
          end
        end
      end
    end
  end
end
