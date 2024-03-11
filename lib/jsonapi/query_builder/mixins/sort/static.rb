# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Sort
        class Static
          attr_reader :attribute, :sort

          def initialize(attribute, sort)
            @attribute = attribute
            @sort = sort || ->(collection, direction) { collection.order(attribute => direction) }
          end

          def results(collection, sort_param)
            if sort.respond_to?(:call)
              sort.call(collection, sort_param.direction)
            else
              sort.new(collection, sort_param.direction).results
            end
          end
        end
      end
    end
  end
end
