# typed: true
# frozen_string_literal: true

module BankApi
  module Data
    class User < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            status: s.enum(%w(open locked)),
            date_of_birth: s.from.string.to(Time).using(:utc, require_offset: false),
            account_ids: s.integer.array,
          },
          optional: {
            nickname: s.string,
          },
        }
      end

      def age
        # NOTE: This isn't actually correct for a variety of reasons, just an example
        ActiveSupport::TimeZone["UTC"].now.year - date_of_birth.year
      end
    end
  end
end
