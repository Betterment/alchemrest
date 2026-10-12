# typed: true
# frozen_string_literal: true

require 'active_support/core_ext/enumerable'
require 'alchemrest'
require 'prism'

module Tapioca
  module Dsl
    module Compilers
      # This compiler generates RBI files for classes that inherit from `Alchemrest::Root`.
      #
      # For example, given the following classes:
      #
      #   class UpdateProfile < Alchemrest::Request
      #     extend T::Sig
      #
      #     sig { params(id: Integer, name: String).void }
      #     def initialize(id:, name:)
      #       ...
      #     end
      #
      #     returns Profile
      #   end
      #
      #   class Root < Alchemrest::Root
      #     define_request :update_profile, UpdateProfile do |request|
      #       request.defaults = { id: }
      #     end
      #   end
      #
      # This compiler will generate an RBI file `root.rbi` with the following content:
      #
      #   sig { params(name: ::String, id: ::Integer).returns(::Alchemrest::Result[::Profile]) }
      #   def update_profile(name:, id: T.unsafe(nil)); end
      #
      class AlchemrestRoot < Tapioca::Dsl::Compiler
        extend T::Sig

        ConstantType = type_member { { upper: T.class_of(Alchemrest::Root) } }

        KEYWORD_PARAM_TYPES = [RBI::KwParam, RBI::KwOptParam, RBI::KwRestParam].freeze

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
                parameters: parameters_for(definition),
                return_type: return_type_for(definition),
              )
            end
          end
        end

        private

        sig { params(definition: Alchemrest::RequestDefinition).returns(T::Array[RBI::TypedParam]) }
        def parameters_for(definition)
          parameters = compile_method_parameters_to_rbi(definition.request_class.instance_method(:initialize))

          if parameters.all? { |typed_param| KEYWORD_PARAM_TYPES.include?(typed_param.param.class) }
            optional_keys = defaulted_keys_for(definition) || parameters.map { |typed_param| typed_param.param.name }
            with_optional_keys(parameters, optional_keys)
          else
            [create_opt_param('params', type: 'T::Hash[Symbol, T.untyped]', default: '{}')]
          end
        end

        sig { params(parameters: T::Array[RBI::TypedParam], optional_keys: T::Array[String]).returns(T::Array[RBI::TypedParam]) }
        def with_optional_keys(parameters, optional_keys)
          parameters = parameters.map do |typed_param|
            param = typed_param.param

            if param.is_a?(RBI::KwParam) && optional_keys.include?(param.name)
              create_kw_opt_param(param.name, type: typed_param.type, default: 'T.unsafe(nil)')
            else
              typed_param
            end
          end

          required, optional = parameters.partition { |typed_param| typed_param.param.is_a?(RBI::KwParam) }
          required + optional
        end

        sig { params(definition: Alchemrest::RequestDefinition).returns(T.nilable(T::Array[String])) }
        def defaulted_keys_for(definition)
          if definition.builder_block
            literal_defaults_keys(block_node_for(definition.builder_block))
          else
            []
          end
        end

        sig { params(block_node: T.nilable(Prism::Node)).returns(T.nilable(T::Array[String])) }
        def literal_defaults_keys(block_node)
          case block_node
          in { body: { body: [Prism::CallNode[name: :defaults=, arguments: { arguments: [Prism::HashNode[elements:]] }]] } }
            symbol_keys = elements.grep(Prism::AssocNode).map(&:key).grep(Prism::SymbolNode)
            symbol_keys.map(&:unescaped) if symbol_keys.size == elements.size
          else
            nil
          end
        end

        sig { params(builder_block: Proc).returns(T.nilable(Prism::Node)) }
        def block_node_for(builder_block)
          file, line = builder_block.source_location

          if file && File.exist?(file)
            Prism.parse_file(file).value.breadth_first_search { |node| node.is_a?(Prism::BlockNode) && node.location.start_line == line }
          end
        end

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
          returns_modules = definition.request_class.ancestors.grep(Alchemrest::Request::Returns)
          returns_modules.sole.domain_type.const_get(:TRANSFORM) if returns_modules.one?
        end
      end
    end
  end
end
