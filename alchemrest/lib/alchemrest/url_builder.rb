# typed: true
# frozen_string_literal: true

module Alchemrest
  class UrlBuilder
    include Anima.new(:template, :query_param_encoder, :values, :query)

    def initialize(args)
      super({ values: nil, query: nil, query_param_encoder: Encoders.find(:form) }.merge(**args.compact))
    end

    def url
      base = values ? Mustermann::Expander.new(template).expand(values) : template

      if query_string
        "#{base}?#{query_string}"
      else
        base
      end
    end

    private

    def query_string
      return nil unless query
      return nil if query.compact.empty?

      query_param_encoder.call(query.compact)
    end
  end
end
