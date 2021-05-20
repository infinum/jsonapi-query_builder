# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module PaginationStrategy
      class Pagy
        include ::Pagy::Backend
        
        attr_reader :params
        attr_reader :page_number
        attr_reader :page_size
        attr_reader :page_offset
        attr_reader :details

        def initialize(params: nil)
          @params = params || {}
          @page_number = @params.dig(:page, :number)
          @page_size = @params.dig(:page, :size)
          @page_offset = @params.dig(:page, :offset)
        end

        # Paginates the collection and returns the requested page. Also sets the pagination details that can be used for
        # displaying metadata in the Json:Api response.
        # @param [ActiveRecord::Relation] collection
        # @param [Object] page_params Optional explicit pagination params
        # @return [ActiveRecord::Relation] Paged collection
        def paginate(collection)
          @details, records = pagy collection, page: page_number,
                                               items: page_size,
                                               outset: page_offset

          records
        end

        def pagination_details
          {
            meta: meta,
            links: links
          }.compact
        end

        private

        def meta
          return {} unless details

          {
            current_page: details.page,
            total_pages: details.pages,
            total_count: details.count,
            padding: details.vars.fetch(:outset).to_i,
            page_size: details.vars.fetch(:items).to_i,
            max_page_size: details.vars.fetch(:max_items).to_i
          }
        end

        def links
          return {} unless details

          {
            self: build_link(details.page),
            first: build_link(1),
            last: build_link(details.last),
            prev: build_link(details.prev),
            next: build_link(details.next)
          }.compact
        end

        def build_link(page)
          return unless page

          link_params = params.deep_dup
          link_params[:page] = {
            number: page,
            size: details.vars.fetch(:items),
            padding: details.vars.fetch(:outset)
          }.compact

          Rails.application.routes.url_helpers.url_for(link_params)
        end
      end
    end
  end
end
