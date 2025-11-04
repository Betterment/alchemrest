# typed: true
# frozen_string_literal: true

require 'active_support/core_ext/enumerable'
require 'alchemrest'

module Tapioca
  module Dsl
    module Compilers
      # This compiler generates RBI files for classes that inherit from `Alchemrest::Data`.
      #
      # For example, given the following class:
      #
      #   class Profile < Alchemrest::Data
      #     schema do |s|
      #       {
      #         required: {
      #           name: s.string,
      #         },
      #       }
      #     end
      #   end
      #
      # This compiler will generate an RBI file `profile.rbi` with the following content:
      #
      #   sig { returns(::String) }
      #   def name; end
      #
      class AlchemrestData < Tapioca::Dsl::Compiler
        extend T::Sig

        Type = T.type_alias { T.any(Class, T::Types::Base) }

        ConstantType = type_member { { upper: T.class_of(Alchemrest::Data) } }

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          descendants_of(Alchemrest::Data)
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |rbi|
            constant.graph.fields.each do |name, field|
              type = T::Utils.coerce(extract_type(field.output_type))
              rbi.create_method(name.to_s, return_type: type.to_s)
            end
          end
        end

        sig { params(output_type: T.nilable(Alchemrest::Transforms::OutputType)).returns(Type) }
        def extract_type(output_type)
          return T.untyped if output_type.nil?

          output_type.sorbet_type
        end

        sig { params(types: T::Array[Class]).returns(Type) }
        def extract_output_type(types)
          types.many? ? T.any(*T.unsafe(types)) : types.sole
        end

        sig { params(field: Alchemrest::Data::Field).returns(T::Boolean) }
        def nilable?(field)
          !field.required || field.transform.is_a?(Morpher::Transform::Maybe)
        end

        sig { params(transform: Morpher::Transform).returns(T::Boolean) }
        def array?(transform)
          case transform
          when Alchemrest::Transforms::Typed
            transform.collection
          when Morpher::Transform::Array
            true
          when Morpher::Transform::Maybe
            array?(transform.send(:transform))
          else
            false
          end
        end
      end
    end
  end
end
