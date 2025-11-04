# frozen_string_literal: true
# typed: true

module BankApi
  module Data
    class Card < Alchemrest::Data
      schema do |s|
        {
          required: {
            source_type: s.enum(%w(card)),
            card_number: s.string,
            expiration_date: s.from.string.to(Time).using(:utc, require_offset: false),
          },
          optional: {
            secondary_user: s.one_of(User),
          }
        }
      end
    end
  end
end
