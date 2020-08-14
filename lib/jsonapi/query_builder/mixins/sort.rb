# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Sort
        extend ActiveSupport::Concern

        UnpermittedSortParameters = Class.new ArgumentError

        class_methods do
          attr_reader :_unique_sort_attributes, :_default_sort, :_sort_attributes

          def unique_sort_attributes(*attributes)
            @_unique_sort_attributes = attributes
          end

          def _unique_sort_attributes
            @_unique_sort_attributes || [id: :asc]
          end

          alias_method :unique_sort_attribute, :unique_sort_attributes

          def default_sort(options)
            @_default_sort = options
          end

          def sorts_by(*attributes)
            @_sort_attributes = (@_sort_attributes || []) + attributes
          end
        end

        def sort(collection, sort_params = send(:sort_params))
          collection
            .reorder(sort_params.nil? ? self.class._default_sort : formatted_sort_params(sort_params))
            .tap(&method(:add_unique_order_attributes))
        end

        private

        def sort_params
          params[:sort]
        end

        def add_unique_order_attributes(collection)
          collection.order(*self.class._unique_sort_attributes)
        end

        def formatted_sort_params(sort_params)
          sort_params
            .split(",")
            .map(&:strip)
            .to_h { |attribute| attribute.start_with?("-") ? [attribute[1..-1], :desc] : [attribute, :asc] }
            .symbolize_keys
            .tap(&method(:ensure_permitted_sort_params!))
        end

        def ensure_permitted_sort_params!(sort_params)
          return if (unpermitted_parameters = sort_params.keys - self.class._sort_attributes.map(&:to_sym)).size.zero?

          raise UnpermittedSortParameters, [
            unpermitted_parameters.to_sentence,
            unpermitted_parameters.count == 1 ? "is not a" : "are not",
            "permitted sort attribute".pluralize(unpermitted_parameters.count)
          ].join(" ")
        end
      end
    end
  end
end
