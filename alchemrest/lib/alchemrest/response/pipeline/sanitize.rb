# frozen_string_literal: true

module Alchemrest
  class Response
    class Pipeline
      class Sanitize < Morpher::Transform
        include Anima.new(:safe)
        PRIMITIVE = Primitive.new(::Hash)

        def initialize(args = { safe: nil })
          @safe = args[:safe]
          super
        end

        def call(input)
          if input.is_a?(::Array)
            array.call(input)
          else
            PRIMITIVE
              .call(input)
              .bind { |i| sanitize(i) }
          end
        end

        private

        def sanitize(input)
          filtered = Alchemrest.parameter_filter.filter(input).with_indifferent_access
          if safe.present?
            copy(input, filtered)
          end
          success(filtered.deep_symbolize_keys)
        end

        def copy(original, filtered)
          safe.each do |safe_path|
            safe_path.walk(filtered) do |path, filtered_node, remaining_segments|
              if remaining_segments.count == 1 && filtered_node.is_a?(::Hash)
                next unless hash_has_key?(original, path, remaining_segments.last)

                original_value = original.with_indifferent_access.dig(*(path + remaining_segments))
                filtered_node[remaining_segments.last] = original_value
              end
            end
          end
        end

        def hash_has_key?(hash, path, key)
          if path.empty?
            hash.with_indifferent_access.key?(key)
          else
            hash.with_indifferent_access.dig(*path)
              .key?(key)
          end
        end
      end
    end
  end
end
