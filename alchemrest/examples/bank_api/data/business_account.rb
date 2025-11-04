# frozen_string_literal: true
# typed: true

module BankApi
  module Data
    class BusinessAccount < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            status: s.enum(%w(open locked)),
            ein: s.string,
            id: s.string,
          },
          optional: {
            nickname: s.string,
          },
        }
      end
    end
  end
end
