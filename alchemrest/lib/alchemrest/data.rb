# frozen_string_literal: true

module Alchemrest
  class Data
    def self.schema
      include Alchemrest::Data::Schema.new(**(yield Alchemrest::Transforms))
    end
  end
end
