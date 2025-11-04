# frozen_string_literal: true

module BankApi
  module Data
    class Ach < Alchemrest::Data
      schema do |s|
        {
          required: {
            source_type: s.enum(%w(ach)),
            trace_number: s.from.string.where.max_length(15),
          },
        }
      end
    end
  end
end
