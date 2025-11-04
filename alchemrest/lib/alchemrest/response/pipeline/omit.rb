# frozen_string_literal: true

module Alchemrest
  class Response
    class Pipeline
      class Omit < Morpher::Transform
        include Concord::Public.new(:omit)
        private_constant(*constants(false))
        PRIMITIVE = Primitive.new(::Hash)

        def initialize(omit = nil)
          @omit = omit
          super
        end

        def call(input)
          if input.is_a?(::Array)
            array.call(input)
          else
            PRIMITIVE
              .call(input)
              .bind { |i| omit_nodes(i) }
          end
        end

        def omit_nodes(input)
          dup = input.dup
          if omit.present?
            delete_from(dup)
          end
          success(dup)
        end

        def delete_from(input)
          omit.each do |path|
            path.walk(input) do |_path, node, remaining_segments|
              if remaining_segments.count == 1
                node.delete(remaining_segments.last)
              end
            end
          end
        end
      end
    end
  end
end
