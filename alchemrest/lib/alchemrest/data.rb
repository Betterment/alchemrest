# frozen_string_literal: true

module Alchemrest
  class Data
    # Mutant only finds equivalent mutants here: these constants resolve the
    # same with or without their Alchemrest:: prefix inside this namespace.
    # mutant:disable
    def self.schema(&)
      include Alchemrest::Data::Schema.new(**(yield Alchemrest::Transforms))
    end
  end
end
