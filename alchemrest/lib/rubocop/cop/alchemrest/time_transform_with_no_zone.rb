# frozen_string_literal: true

module RuboCop
  module Cop
    module Alchemrest
      class TimeTransformWithNoZone < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = <<~MSG
          Calling `s.from.string.to(Time)` without specifying the timezone is no longer supported

          BAD:
          ```
          s.from.string.to(Time)
          ```

          GOOD:
          ```
          s.from.string.to(Time).using(:utc)
          s.from.string.to(Time).using(:local)
          s.from.string.to(Time).using(ActiveSupport::TimeZone['Mountain Time (US & Canada)'])
          ```
        MSG

        def_node_matcher :on_time_transform?, <<~PATTERN
          (send (send (send ... :from) :string) :to (const nil? :Time))
        PATTERN

        def_node_matcher :on_good_time_transform?, <<~PATTERN
          (send (send (send (send ... :from) :string) :to (const nil? :Time)) :using ...)
        PATTERN

        def on_hash(node)
          node.pairs.each do |pair|
            transform_node = pair.value

            next if on_good_time_transform?(transform_node)

            on_time_transform?(transform_node) do
              add_offense(transform_node) do |corrector|
                correction = build_autocorrection(transform_node)
                corrector.replace(transform_node, correction) if correction
              end
            end
          end
        end

        def build_autocorrection(node)
          <<~CODE.chomp
            #{node.source}.using(:utc)
          CODE
        end
      end
    end
  end
end
