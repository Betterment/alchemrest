# frozen_string_literal: true

module BankApi
  class PositiveInterestString < Morpher::Transform
    attr_reader :decimal_places

    def initialize(decimal_places) # rubocop:disable Lint/MissingSuper
      @decimal_places = decimal_places
    end

    def call(input)
      return failure(error(message: "Expected a string of the form '<num>%", input:)) unless input[-1] == "%"

      decimal = BigDecimal(input.chop)
      if input.chop.split(".")[1].length != decimal_places
        failure(error(message: "Expected #{input} to have #{decimal_places} decimal_places", input:))
      elsif decimal.negative?
        failure(error(message: "#{input} is less than 0%", input:))
      else
        success(decimal)
      end
    rescue ArgumentError => e
      raise unless e.message.start_with? "invalid value for BigDecimal()"

      failure(
        error(
          message: "Expected: #{input} to be a decimal",
          input:,
        ),
      )
    end
  end
end
