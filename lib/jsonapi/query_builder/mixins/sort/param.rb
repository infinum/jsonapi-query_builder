# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Sort
        class Param
          class << self
            def deserialize_params(sort_params)
              (sort_params || "").split(",").map(&method(:new))
            end
          end

          attr_reader :descending, :attribute

          def initialize(param)
            @descending, @attribute = deserialize(param)
          end

          def deserialize(param)
            _, descending, attribute = param.strip.match(/^(?<descending>-)?(?<attribute>.*)$/).to_a

            [descending, attribute]
          end

          def serialize
            [descending, attribute].compact.join
          end

          def direction
            descending.present? ? :desc : :asc
          end
        end
      end
    end
  end
end
