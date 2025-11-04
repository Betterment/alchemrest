# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RuboCop::Cop::Alchemrest::RequestHashReturningBlock, :config do
  include RuboCop::RSpec::ExpectOffense

  describe "#on_send" do
    context 'with a simple block returning a hash' do
      it 'registers and correct an offense' do
        expect_offense(<<~RUBY)
          endpoint :get, '/api/users/:id', -> { { id: id } }
                                           ^^^^^^^^^^^^^^^^^ Returning a hash to set url params is deprecated. [...]
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, '/api/users/:id' do |url|
            url.params = { id: id }
          end
        RUBY
      end
    end

    context "with a path parameter that uses interploation" do
      it 'registers the offense and autocorrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "\#{PREFIX}/api/users/:id", -> { { id: id } }
                                                    ^^^^^^^^^^^^^^^^^ Returning a hash to set url params is deprecated. [...]
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "\#{PREFIX}/api/users/:id" do |url|
            url.params = { id: id }
          end
        RUBY
      end
    end

    context 'with a block returning a more complex hash' do
      it 'registers the offense and auto corrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "/v1/users/:id", -> { { id: @user_object.id } }
                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Returning a hash to set url params is deprecated. [...]
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.params = { id: @user_object.id }
          end
        RUBY
      end
    end

    context 'with a block returning a nested hash' do
      it 'registers the offense and auto corrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "/v1/users/:id", -> { { nested: { id: @user_object.id } } }
                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Returning a hash to set url params is deprecated. [...]
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.params = { nested: { id: @user_object.id } }
          end
        RUBY
      end
    end

    context 'with a block returning a hash defined via a method' do
      it 'registers the offense and autocorrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "/v1/users/:id", -> { args }
                                          ^^^^^^^^^^^ Returning a hash to set url params is deprecated. [...]
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.params = args
          end
        RUBY
      end
    end

    context 'with a block wrapped in a bind helper' do
      it 'registers the offense and autocorrects' do
        expect_offense(<<~RUBY)
          endpoint :get, "/v1/users/:id", bind_self { { id: user_id } }
                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Returning a hash to set url params is deprecated. [...]
        RUBY

        expect_correction(<<~RUBY)
          endpoint :get, "/v1/users/:id" do |url|
            url.params = { id: user_id }
          end
        RUBY
      end
    end
  end
end
