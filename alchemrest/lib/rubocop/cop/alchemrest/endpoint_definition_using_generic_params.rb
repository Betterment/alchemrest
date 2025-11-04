# frozen_string_literal: true

module RuboCop
  module Cop
    module Alchemrest
      class EndpointDefinitionUsingGenericParams < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = <<~MSG
          You are using a generic params hash to build a url, rather than explicitly defining which values in the
          hash should be inserted into the path of the url, vs which are query string params. This is deprecated,
          and you should update your code to use `values=` and `query=` instead.

          BAD:
          endpoint :get, '/api/v1/users/:id' do |url|
            url.params = { id: @id, includeDetails: true }
          end

          GOOD:
          endpoint :get, '/api/v1/users/:id' do |url|
            url.values = { id: @id }
            url.query = { includeDetails: true }
          end
        MSG

        def_node_matcher :on_endpoint_call?, <<~PATTERN
          (block (send _ :endpoint ...) (args (arg _)) $_)
        PATTERN

        def_node_matcher :generic_params_assignment?, <<~PATTERN
          (send (lvar $_) :params= _)
        PATTERN

        def on_block(node)
          on_endpoint_call?(node) do |block_node|
            if generic_params_assignment?(block_node)
              add_offense(block_node) do |corrector|
                correction = build_autocorrection(block_node)
                corrector.replace(block_node, correction) if correction
              end
            end
          end
        end

        def build_autocorrection(block)
          params_value = block.arguments.first.source

          <<~CODE.chomp
            url.values = #{params_value}
          CODE
        end
      end
    end
  end
end
