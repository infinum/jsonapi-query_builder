# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Sort
        extend ActiveSupport::Concern

        UnpermittedSortParameters = Class.new ArgumentError

        class_methods do
          attr_reader :_default_sort

          def _unique_sort_attributes
            @_unique_sort_attributes || [id: :asc]
          end

          def _sort_attributes
            @_sort_attributes || []
          end

          def unique_sort_attributes(*attributes)
            @_unique_sort_attributes = attributes
          end
          alias_method :unique_sort_attribute, :unique_sort_attributes

          def default_sort(options)
            @_default_sort = options
          end

          def sorts_by(*attributes, **nested_attributes)
            nested_sort_attributes = _sort_attributes.extract_options!
            @_sort_attributes = _sort_attributes + attributes + [nested_sort_attributes.deep_merge(nested_attributes)]
          end
        end

        def sort(collection, sort_params = send(:sort_params))
          ensure_permitted_sort_params!(sort_params) if sort_params

          collection
            .yield_self { |c| add_joins_for_nested_attributes(c, sort_params) }
            .yield_self { |c| add_order_attributes(c, sort_params) }
            .yield_self(&method(:add_unique_order_attributes))
        end

        private

        def sort_params
          params[:sort]
        end

        def ensure_permitted_sort_params!(sort_params)
          unpermitted_parameters =
            sort_params
              .split(",")
              .map(&method(:deserialize_param))
              .reject { |_, model, attribute|
                (model.nil? ? self.class._sort_attributes : self.class._sort_attributes[-1].fetch(model.to_sym, []))
                  .include?(attribute.to_sym)
              }
              .map { |_, model, param| serialize_param(nil, model, param) }

          return if unpermitted_parameters.size.zero?

          raise UnpermittedSortParameters, [
            unpermitted_parameters.to_sentence,
            unpermitted_parameters.count == 1 ? "is not a" : "are not",
            "permitted sort attribute".pluralize(unpermitted_parameters.count)
          ].join(" ")
        end

        def add_joins_for_nested_attributes(collection, sort_params)
          relationships =
            sort_params
              &.split(",")
              &.map { |param| deserialize_param(param)[1] }
              &.compact
              &.uniq
              &.map(&:to_sym)

          relationships.present? ? collection.left_joins(*relationships) : collection
        end

        def add_order_attributes(collection, sort_params)
          collection.reorder(sort_params.nil? ? self.class._default_sort : formatted_sort_params(sort_params))
        end

        def add_unique_order_attributes(collection)
          collection.order(*self.class._unique_sort_attributes)
        end

        def formatted_sort_params(sort_params)
          sort_params.split(",").map(&method(:format_param))
        end

        def deserialize_param(param)
          _, desc, model, attribute = param.strip.match(/^(?<desc>-)?(?>(?<model>[^.]*)\.)*(?<attribute>.*)$/).to_a

          [desc, model, attribute]
        end

        def serialize_param(desc, model, attribute)
          model &&= "#{model}."

          [desc, model, attribute].compact.join
        end

        def format_param(attribute_parameter)
          desc, model, attribute = deserialize_param attribute_parameter

          direction = desc.present? ? :desc : :asc

          (model.present? ? model.classify.constantize.arel_table[attribute] : Arel.sql(attribute)).send(direction)
        end
      end
    end
  end
end
