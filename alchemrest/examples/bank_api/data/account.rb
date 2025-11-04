# frozen_string_literal: true
# typed: true

module BankApi
  module Data
    class Account < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            status: s.enum(%w(open locked)),
            cards: s.many_of(BankApi::Data::Card),
          },
          optional: {
            nickname: s.string,
          },
        }
      end
    end
  end
end
