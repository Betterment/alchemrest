# frozen_string_literal: true

module Alchemrest
  # A class that can be used to build an instance of an Alchemrest::Request class. The definition consists of the request class
  # we want to create, and block that can extract default parameters from an Alchemrest::Root. When we want to build an
  # instance of the request, call `build_request` and pass in the root as context, with any additional parameters.
  class RequestDefinition
    attr_reader :name

    def initialize(name, request_class, &block)
      @name = name
      @request_class = request_class
      @builder_block = block
    end

    def build_request(context, params = {})
      builder = Builder.new

      if @builder_block
        context.instance_exec(builder, &@builder_block)
      end

      @request_class.new(**builder.defaults.merge(params))
    end
  end
end
