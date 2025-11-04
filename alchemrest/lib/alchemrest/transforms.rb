# frozen_string_literal: true

module Alchemrest
  # The Transforms module is passed into the block provided to `Alchemrest::Data.schema`, giving developers an easy way to
  # define the transforms for a given data class
  #
  # @example Using `Alchemrest::Transforms` inside a `schema` block
  #   class User < Alchemrest::Data
  #     schema do |s|
  #       # `s` is `Alchemrest::Transforms`
  #     end
  #   end
  module Transforms
    # A transformation that results in an integer number. Must be a true integer in JSON, not a string as number. Will
    # result in a `Alchemrest::MorpherTransformError` if not an integer number.
    def self.integer
      Typed.new(transform: Morpher::Transform::INTEGER, output_type: OutputType.simple(Integer))
    end

    # A transformation that results in a string. Must be a true string in JSON, we will not coerce booleans or number to strings. Will
    # result in a `Alchemrest::MorpherTransformError` if not a string.
    def self.string
      Typed.new(transform: Morpher::Transform::STRING, output_type: OutputType.simple(String))
    end

    # A transformation that results in a float. Must be a float in JSON, we will coerce strings into numbers. Will
    # result in a `Alchemrest::MorpherTransformError` if not a float. Note, if the api sometimes returns a float and
    # sometimes returns an integer, see {#number} instead.
    def self.float
      Typed.new(transform: Morpher::Transform::FLOAT, output_type: OutputType.simple(Float))
    end

    def self.from
      FromChain
    end

    # A transformation that results in some kind of numeric type, generally either a Float or Integer. If the input is not
    # Numeric, will result in a `Alchemrest::MorpherTransformError`
    def self.number
      Typed.new(transform: Number.new, output_type: OutputType.simple(T.any(Float, Integer)))
    end

    # A transformation that results in a boolean. If the input is not a boolean, will result in a `Alchemrest::MorpherTransformError`
    def self.boolean
      Typed.new(transform: Morpher::Transform::BOOLEAN, output_type: OutputType.simple(T::Boolean))
    end

    # A transformation that results in a Date object.
    # If the input is not an iso8601 date string, will result in a `Alchemrest::MorpherTransformError`
    def self.date
      Typed.new(transform: DateTransform.new, output_type: OutputType.simple(Date))
    end

    # A transformation that creates a {Money} object. You can indicate
    # whether the original amount is in dollars our cents via the unit
    # param. If the original value is not numeric, it will result in a
    # `Alchemrest::MorpherTransformError`
    #
    # @param [Symbol] (:dollars | :cents) the unit for the original amount
    def self.money(unit)
      Typed.new(transform: MoneyTransform.new(unit), output_type: OutputType.simple(Money))
    end

    # A transformation that results in a {Symbol, String} from a predefined list.
    # If the original value is not a string from the predefined list, it will
    # result in a `Alchemrest::MorpherTransformError`
    #
    # @param [Array<Symbol>] the list of valid values for the field
    def self.enum(enum)
      Typed.new(transform: Enum.new(enum), output_type: OutputType.simple(T.any(Symbol, String)))
    end

    # A transformation that results in an Alchemrest::Data class. You can
    # either provide a klass or a Hash with a `discriminator` value for
    # polymorphic data types
    #
    # @param [Class, Hash<Symbol, Class>] Either an `Alchemrest::Data` class,
    #        or a hash of classes along with a `discriminator` key for polymorphic
    #        use cases
    def self.one_of(klass_or_hash)
      if klass_or_hash.instance_of? Hash
        klasses = klass_or_hash.except(:discriminator)
        Union.new(types: klasses, discriminator: klass_or_hash.fetch(:discriminator))
      else
        klass_or_hash::TRANSFORM
      end
    end

    def self.many_of(klass)
      klass::TRANSFORM.array
    end
  end
end
