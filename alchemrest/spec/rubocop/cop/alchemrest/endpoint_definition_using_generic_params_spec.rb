# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RuboCop::Cop::Alchemrest::EndpointDefinitionUsingGenericParams, :config do
  include RuboCop::RSpec::ExpectOffense

  describe "#on_send" do
    context 'with a simple block using the builder' do
      it 'registers and correct an offense' do
        expect_offense(<<~RUBY)
          endpoint :get, '/api/users/:id' do |url|
            url.params = { id: id }
            ^^^^^^^^^^^^^^^^^^^^^^^ You are using a generic params hash to build a url, [...]
          end
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, '/api/users/:id' do |url|
            url.values = { id: id }
          end
        RUBY
      end
    end

    context "with a path parameter that uses interploation" do
      it 'registers the offense and autocorrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "\#{PREFIX}/api/users/:id" do |url|
            url.params = { id: id }
            ^^^^^^^^^^^^^^^^^^^^^^^ You are using a generic params hash to build a url, [...]
          end
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "\#{PREFIX}/api/users/:id" do |url|
            url.values = { id: id }
          end
        RUBY
      end
    end

    context 'with a block setting a more complex hash' do
      it 'registers the offense and auto corrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.params = { id: @user_object.id }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ You are using a generic params hash to build a url, [...]
          end
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.values = { id: @user_object.id }
          end
        RUBY
      end
    end

    context 'with a block setting a nested hash' do
      it 'registers the offense and auto corrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.params = { nested: { id: @user_object.id } }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ You are using a generic params hash to build a url, [...]
          end
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.values = { nested: { id: @user_object.id } }
          end
        RUBY
      end
    end

    context 'with a block setting a hash defined via a method' do
      it 'registers the offense and autocorrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.params = args
            ^^^^^^^^^^^^^^^^^ You are using a generic params hash to build a url, [...]
          end
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.values = args
          end
        RUBY
      end
    end
  end
end
