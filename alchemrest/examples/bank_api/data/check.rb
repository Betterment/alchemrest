# frozen_string_literal: true
# typed: true

module BankApi
  module Data
    class Check < Alchemrest::Data
      schema do |s|
        {
          required: {
            source_type: s.enum(%w(check)),
            check_number: s.integer,
            check_image_back_url: s.string,
            check_image_front_url: s.string,
          },
        }
      end
    end
  end
end
