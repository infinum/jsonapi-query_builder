# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Include
        class Param
          class << self
            def deserialize_params(include_params)
              (include_params || "")
                .split(",")
                .map(&method(:new))
                .each_with_object([]) { |param, memo|
                  if (existing_param = memo.find { |existing_param| existing_param.relationship == param.relationship })
                    existing_param.merge_children(param)
                  else
                    memo << param
                  end
                }
            end
          end

          attr_reader :relationship, :children

          def initialize(param)
            @children = []
            @relationship = deserialize(param)
          end

          def merge_children(other)
            other.children.each do |child|
              if (existing_child = children.find { |existing_param| existing_param.relationship == child.relationship })
                existing_child.merge_children(child)
              else
                children << child
              end
            end

            self
          end

          def serialize
            case children.count
            when 0 then relationship
            when 1 then {relationship => children.first.serialize}
            else {relationship => children.map(&:serialize)}
            end
          end

          private

          def deserialize(param)
            param
              .strip.split(".", 2)
              .yield_self { |(relationship, child)|
                children << self.class.new(child) if child

                relationship.to_sym
              }
          end
        end
      end
    end
  end
end
