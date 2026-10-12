# frozen_string_literal: true

require 'spec_helper'
# Deliberately not requiring `tapioca/internal`: its name patch makes every Sorbet type name print with a leading `::`
# for the rest of the process, which breaks other specs (e.g. introspection_spec). Types below print without the
# prefix that `bin/tapioca dsl` adds.
require 'tapioca/helpers/test/dsl_compiler'
require 'tapioca/dsl/compilers/alchemrest_root'

RSpec.describe Tapioca::Dsl::Compilers::AlchemrestRoot do
  describe '#decorate' do
    subject(:rbi) { Tapioca::Helpers::Test::DslCompiler::CompilerContext.new(described_class).rbi_for('SpecRoot') }

    before do
      stub_const('UpdateProfile', Class.new(Alchemrest::Request) do
        extend T::Sig

        sig { params(id: Integer, name: String, nickname: T.nilable(String)).void }
        def initialize(id:, name:, nickname: nil) # rubocop:disable Lint/MissingSuper
          @id = id
          @name = name
          @nickname = nickname
        end

        returns BankApi::Data::User
      end)
    end

    context 'when the request is defined without defaults' do
      before do
        stub_const('SpecRoot', Class.new(Alchemrest::Root) do
          define_request :update_profile, UpdateProfile
        end)
      end

      it 'generates keyword arguments typed from the request initializer' do
        expect(rbi).to eq(<<~RBI)
          # typed: strong

          class SpecRoot
            sig { params(id: Integer, name: String, nickname: T.nilable(String)).returns(::Alchemrest::Result[BankApi::Data::User]) }
            def update_profile(id:, name:, nickname: T.unsafe(nil)); end
          end
        RBI
      end
    end

    context 'when the request is defined with literal defaults' do
      before do
        stub_const('SpecRoot', Class.new(Alchemrest::Root) do
          define_request :update_profile, UpdateProfile do |request|
            request.defaults = { id: 1 }
          end
        end)
      end

      it 'makes the defaulted keyword arguments optional' do
        expect(rbi).to eq(<<~RBI)
          # typed: strong

          class SpecRoot
            sig { params(name: String, id: Integer, nickname: T.nilable(String)).returns(::Alchemrest::Result[BankApi::Data::User]) }
            def update_profile(name:, id: T.unsafe(nil), nickname: T.unsafe(nil)); end
          end
        RBI
      end
    end

    context 'when the request is defined with defaults that are not a literal hash' do
      before do
        stub_const('SpecRoot', Class.new(Alchemrest::Root) do
          define_request :update_profile, UpdateProfile do |request|
            request.defaults = profile_defaults
          end
        end)
      end

      it 'makes every keyword argument optional' do
        expect(rbi).to eq(<<~RBI)
          # typed: strong

          class SpecRoot
            sig { params(id: Integer, name: String, nickname: T.nilable(String)).returns(::Alchemrest::Result[BankApi::Data::User]) }
            def update_profile(id: T.unsafe(nil), name: T.unsafe(nil), nickname: T.unsafe(nil)); end
          end
        RBI
      end
    end

    context 'when the request initializer takes no arguments' do
      before do
        stub_const('SpecRoot', Class.new(Alchemrest::Root) do
          define_request :get_products, BankApi::Requests::GetProducts
        end)
      end

      it 'generates a method without parameters' do
        expect(rbi).to eq(<<~RBI)
          # typed: strong

          class SpecRoot
            sig { returns(::Alchemrest::Result[T::Array[BankApi::Data::Product]]) }
            def get_products; end
          end
        RBI
      end
    end

    context 'when the request initializer takes a keyword splat' do
      before do
        stub_const('SearchProfiles', Class.new(Alchemrest::Request) do
          def initialize(**filters) # rubocop:disable Lint/MissingSuper
            @filters = filters
          end
        end)

        stub_const('SpecRoot', Class.new(Alchemrest::Root) do
          define_request :search_profiles, SearchProfiles
        end)
      end

      it 'generates a keyword splat' do
        expect(rbi).to eq(<<~RBI)
          # typed: strong

          class SpecRoot
            sig { params(filters: T.untyped).returns(::Alchemrest::Result[T.untyped]) }
            def search_profiles(**filters); end
          end
        RBI
      end
    end

    context 'when the request initializer takes positional arguments' do
      before do
        stub_const('SpecRoot', Class.new(Alchemrest::Root) do
          define_request :post_transaction, BankApi::Requests::PostTransaction
        end)
      end

      it 'falls back to a hash of params' do
        expect(rbi).to eq(<<~RBI)
          # typed: strong

          class SpecRoot
            sig { params(params: T::Hash[Symbol, T.untyped]).returns(::Alchemrest::Result[T.untyped]) }
            def post_transaction(params = {}); end
          end
        RBI
      end
    end
  end
end
