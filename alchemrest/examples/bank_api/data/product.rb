# frozen_string_literal: true
# typed: true

module BankApi
  module Data
    class Product < Alchemrest::Data
      schema do |s|
        {
          required: {
            name: s.string,
            interest_rate: PositiveInterestString.new(2),
            partner_revenue_rate: s.from.string.where.matches(/^\d+(?:\.\d{1,4})?$/).to(BigDecimal).where("less than 10") do |input|
                                    input < 10
                                  end,
          },
        }
      end
    end
  end
end
