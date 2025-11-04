# frozen_string_literal: true

module RuboCop
  module Cop
    module Alchemrest
      class RequestHashReturningBlock < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = <<~MSG
          Returning a hash to set url params is deprecated. Instead make your block take a `url` argument and call `url.params = {...}`

            BAD:
            ```
            endpoint :get, '/api/users/:id', -> { { id: user_id } }
            ```

            GOOD:
            ```
            endpoint :get, '/api/users/:id' do |url|
              url.params = { id: user_id }
            end
            ```
        MSG

        def_node_matcher :on_endpoint_params_proc_call?, <<~PATTERN
          (send nil? :endpoint $(sym _) $({str | dstr} ...) $(block ...))
        PATTERN

        def on_send(node)
          on_endpoint_params_proc_call?(node) do |http_method, url, block_node|
            add_offense(block_node) do |corrector|
              correction = build_autocorrection(http_method, url, block_node)
              corrector.replace(node, correction) if correction
            end
          end
        end

        def build_autocorrection(http_method, url, block)
          block_body = block.body

          params_value = block_body.source

          url_string = url.source

          <<~CODE.chomp
            endpoint :#{http_method.value}, #{url_string} do |url|
              url.params = #{params_value}
            end
          CODE
        end
      end
    end
  end
end
