# frozen_string_literal: true

module RuboCop
  module Cop
    module Alchemrest
      class DefineRequestUsingWithParams < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = <<~MSG
          Using `with_params` to set defaults for a request is deprecated.
          Instead make your block that takes a `request` argument and call `request.defaults = { <some values> }`

            BAD:
            ```
            define_request :get_users, GetUsers, with_params: -> { { id: user_id } }
            ```

            GOOD:
            ```
            define_request :get_users, GetUsers do |request|
              request.defaults = { id: user_id }
            end
            ```
        MSG

        def_node_matcher :on_define_request_with_params_proc_call?, <<~PATTERN
          (send nil? :define_request $(sym _) $(const ...) $(hash (pair (sym :with_params) $(block ...))))
        PATTERN

        def on_send(node)
          on_define_request_with_params_proc_call?(node) do |method_name, klass, with_params_arg, block_node|
            add_offense(with_params_arg) do |corrector|
              correction = build_autocorrection(method_name, klass, block_node)
              corrector.replace(node, correction) if correction
            end
          end
        end

        def build_autocorrection(method_name, klass, block)
          block_body = block.body

          params_value = block_body.source

          <<~CODE.chomp
            define_request #{method_name.source}, #{klass.source} do |request|
              request.defaults = #{params_value}
            end
          CODE
        end
      end
    end
  end
end
