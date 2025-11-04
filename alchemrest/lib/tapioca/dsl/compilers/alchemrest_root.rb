# typed: true
# frozen_string_literal: true

require 'active_support/core_ext/enumerable'
require 'alchemrest'

module Tapioca
  module Dsl
    module Compilers
      # This compiler generates RBI files for classes that inherit from `Alchemrest::Root`.
      #
      # For example, given the following class:
      #
      #   class Root < Alchemrest::Root
      #     define_request :get_profile, Requests::GetProfile
      #   end
      #
      # This compiler will generate an RBI file `root.rbi` with the following content:
      #
      #   sig { params(params: T::Hash[Symbol, T.untyped]).returns(::Alchemrest::Result[::Profile]) }
      #   def get_profile(params = {}); end
      #
      class AlchemrestRoot < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { upper: T.class_of(Alchemrest::Root) } }

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          descendants_of(Alchemrest::Root)
        end

        sig { override.void }
        def decorate
          root.create_path(constant) do |rbi|
            constant.request_definitions.each do |name, definition|
              rbi.create_method(
                name.to_s,
                parameters: [create_opt_param('params', type: 'T::Hash[Symbol, T.untyped]', default: '{}')],
                return_type: return_type_for(definition),
              )
            end
          end
        end

        private

        sig { params(definition: Alchemrest::RequestDefinition).returns(String) }
        def return_type_for(definition)
          transform = extract_transform(definition)

          if transform.nil? || !transform.respond_to?(:output_type)
            '::Alchemrest::Result[T.untyped]'
          else
            "::Alchemrest::Result[#{transform.output_type.sorbet_type}]"
          end
        end

        sig { params(definition: Alchemrest::RequestDefinition).returns(T.nilable(Alchemrest::Transforms::Typed)) }
        def extract_transform(definition)
          request_class = definition.instance_variable_get(:@request_class)
          returns_modules = request_class.ancestors.grep(Alchemrest::Request::Returns)
          returns_modules.sole.domain_type.const_get(:TRANSFORM) if returns_modules.one?
        end
      end
    end
  end
end
