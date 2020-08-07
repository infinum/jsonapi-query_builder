# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Mixins
      module Include
        def add_includes(collection, include_params = send(:include_params))
          collection.includes(formatted_include_params(include_params))
        end

        private

        def include_params
          params[:include]
        end

        def formatted_include_params(include_params)
          return [] unless include_params

          include_params
            .split(",")
            .map(&:strip)
            .map(&method(:formatted_includes_relationship))
        end

        def formatted_includes_relationship(relationship)
          parent, children = relationship.split(".", 2)

          return parent.to_sym unless children

          {parent.to_sym => formatted_includes_relationship(children)}
        end
      end
    end
  end
end
