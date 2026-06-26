# frozen_string_literal: true

module Alchemrest
  class Data
    def self.schema(&)
      include Schema.new(**(yield Transforms))
    end
  end
end
