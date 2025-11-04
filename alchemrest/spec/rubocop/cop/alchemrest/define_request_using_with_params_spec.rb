# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RuboCop::Cop::Alchemrest::DefineRequestUsingWithParams, :config do
  include RuboCop::RSpec::ExpectOffense

  describe "#on_send" do
    context 'with a simple block returning a hash' do
      it 'registers and correct an offense' do
        expect_offense(<<~RUBY)
          define_request :get_users, GetUsers, with_params: -> { { id: id } }
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `with_params` to set defaults [...]
        RUBY

        expect_correction(<<~RUBY)
          define_request :get_users, GetUsers do |request|
            request.defaults = { id: id }
          end
        RUBY
      end
    end

    context 'with a nested const' do
      it 'registers and correct an offense' do
        expect_offense(<<~RUBY)
          define_request :get_users, Test::GetUsers, with_params: -> { { id: id } }
                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `with_params` to set defaults [...]
        RUBY

        expect_correction(<<~RUBY)
          define_request :get_users, Test::GetUsers do |request|
            request.defaults = { id: id }
          end
        RUBY
      end
    end

    context 'with a block returning a more complex hash' do
      it 'registers the offense and auto corrects' do
        expect_offense(<<~RUBY)
          define_request :get_users, GetUsers, with_params: -> { { id: @user_object.id } }
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `with_params` to set defaults [...]
        RUBY

        expect_correction(<<~RUBY)
          define_request :get_users, GetUsers do |request|
            request.defaults = { id: @user_object.id }
          end
        RUBY
      end
    end

    context 'with a block returning a nested hash' do
      it 'registers the offense and auto corrects' do
        expect_offense(<<~RUBY)
          define_request :get_users, GetUsers, with_params: -> { { nested: { id: @user_object.id } } }
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `with_params` to set defaults [...]
        RUBY

        expect_correction(<<~RUBY)
          define_request :get_users, GetUsers do |request|
            request.defaults = { nested: { id: @user_object.id } }
          end
        RUBY
      end
    end

    context 'with a block returning a hash defined via a method' do
      it 'registers the offense and autocorrects' do
        expect_offense(<<~RUBY)
          define_request :get_users, GetUsers, with_params: -> { args }
                                               ^^^^^^^^^^^^^^^^^^^^^^^^ Using `with_params` to set defaults [...]
        RUBY

        expect_correction(<<~RUBY)
          define_request :get_users, GetUsers do |request|
            request.defaults = args
          end
        RUBY
      end
    end

    context 'with a block wrapped in a bind helper' do
      it 'registers the offense and autocorrects' do
        expect_offense(<<~RUBY)
          define_request :get_users, GetUsers, with_params: bind_self { { id: user_id } }
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `with_params` to set defaults [...]
        RUBY

        expect_correction(<<~RUBY)
          define_request :get_users, GetUsers do |request|
            request.defaults = { id: user_id }
          end
        RUBY
      end
    end
  end
end
