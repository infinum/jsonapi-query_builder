# frozen_string_literal: true

module Jsonapi
  module QueryBuilder
    module Errors
      class UnpermittedSortParameters < ArgumentError
        def initialize(unpermitted_parameters)
          super [
            unpermitted_parameters.to_sentence,
            unpermitted_parameters.count == 1 ? "is not a" : "are not",
            "permitted sort attribute".pluralize(unpermitted_parameters.count)
          ].join(" ")
        end
      end
    end
  end
end
