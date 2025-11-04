# frozen_string_literal: true

module Alchemrest
  class EndpointDefinition
    VALID_HTTP_METHODS = IceNine.deep_freeze(%w(get post put delete head patch options trace).to_set)
    private_constant(:VALID_HTTP_METHODS)

    include Anima.new(:template, :http_method, :builder_block)

    def initialize(template:, http_method:, builder_block:)
      super
      raise ArgumentError, "template must be string" unless template.instance_of?(String)

      raise ArgumentError, "missing template" if template.empty?

      downcased_http_method = http_method.downcase
      raise ArgumentError, "must provide a valid HTTP method" unless VALID_HTTP_METHODS.include?(downcased_http_method)
    end

    def url_for(context)
      build_for(context).url
    end

    def params_for(context)
      builder = build_for(context)
      if builder.params
        builder.params
      elsif builder.values || builder.query
        (builder.values || {}).merge(builder.query || {}).transform_values { |v| CGI.escape(v.to_s) }
      end
    end

    private

    def build_for(context)
      options = UrlBuilder::Options.new
      if builder_block&.arity&.zero?
        Alchemrest.deprecator.warn HASH_RETURNING_BLOCK_MESSAGE
        options.params = context.instance_exec(&builder_block)
      elsif builder_block
        context.instance_exec(options, &builder_block)
      end

      options.create_builder(template:)
    end
  end
end
