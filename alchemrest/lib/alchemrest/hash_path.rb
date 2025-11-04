# frozen_string_literal: true

module Alchemrest
  # A utility for executing transformations against hashes scoped to specific parts of the hash
  # defined by the `segments` of the path. The `Alchemrest::HashPath` class has one method `#walk`
  # which will "walk" the path defined by the segments, yielding to a block provided by the calling code
  # at each node it stops at. In that block, the calling code can transform the hash as it likes
  #
  # @example Using `Alchemrest::HashPath` to delete specific nodes from a hash
  #   input = { user: { accounts: [{account_id: 1, transactions: [{transaction_id: 1, amount: 100}] }] } }
  #   path = Alchemrest::HashPath.new([:user, :accounts, :transactions, :amount])
  #   path.walk(input) do |_path, node, remaining_segments|
  #     if(remaining_segments.count == 1)
  #       node.delete(remaining_segments.last.key)
  #     end
  #   end
  #   input #=> { user: { accounts: [{account_id: 1, transactions: [{transaction_id: 1}] }] } }
  class HashPath
    include Concord::Public.new(:segments)

    # A helper method to quickly build a collection of hash paths from a rails style "StrongParams" hash arg.
    # @example Create multiple hash paths from a strong params style hash
    #  Alchemrest::HashPath.build_collection(user: { accounts: { transactions: [:id, :amount] } }) #=>
    #    [
    #      Alchemrest::HashPath(segments: [:accounts, :transactions, :id]),
    #      Alchemrest::HashPath(segments: [:accounts, :transactions, :amount])
    #    ]
    def self.build_collection(definition)
      paths = []
      visit_leaves(definition) do |value, path|
        paths << (path + [value])
      end
      paths.map { |path| new(path) }
    end

    # "Walks" the path defined by the segments of the HashPath, including individual items in nested collections.
    # For each items it walks, it yields to the provided block, passing the current full path to that item, it's value
    # and the remaining segments of the path it has to walk. If it any point the input does not have a value for one
    # of the segments, this method will stop traversing that portion of the hash. Note actions taken within the block
    # are mutative, and will modify the original hash
    def walk(input, &block)
      traverse(input, segments, [], &block)
    end

    class << self
      private

      def visit_leaves(input, path = [], &block)
        case input
          when Hash
            input.each_with_object(path) do |(key, value), path|
              visit_leaves(value, path + [key], &block)
            end
          when Array
            input.map { |i| visit_leaves(i, path, &block) }
          else
            yield input, path
        end
      end
    end

    private

    def traverse(node, remaining_segments, path, &block) # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize
      yield path, node, remaining_segments

      return if remaining_segments.empty?

      current_segment = remaining_segments.first

      if node.is_a?(Hash) && node.key?(current_segment)
        rest_of_segments = remaining_segments[1..]
        traverse(node[current_segment], rest_of_segments, path + [current_segment], &block)
      elsif node.is_a?(Array) && node.any?(Hash)
        node.each_with_index do |item, i|
          traverse(item, remaining_segments, path + [i], &block) if item.is_a?(Hash)
        end
      end
    end
  end
end
