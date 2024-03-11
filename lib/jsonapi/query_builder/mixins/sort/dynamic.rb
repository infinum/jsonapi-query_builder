# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Sort
        class Dynamic
          attr_reader :attribute_prefix, :sort

          def initialize(attribute_prefix, sort)
            @attribute_prefix = attribute_prefix.to_s
            @sort = sort
          end

          def matches?(sort_attribute)
            sort_attribute.to_s.start_with?(attribute_prefix)
          end

          def results(collection, sort_param)
            dynamic_attribute = sort_param.attribute.sub(attribute_prefix, "")
            if sort.respond_to?(:call)
              sort.call(collection, dynamic_attribute, sort_param.direction)
            else
              sort.new(collection, dynamic_attribute, sort_param.direction).results
            end
          end
        end
      end
    end
  end
end
