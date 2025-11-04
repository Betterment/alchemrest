# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RuboCop::Cop::Alchemrest::TimeTransformWithNoZone, :config do
  include RuboCop::RSpec::ExpectOffense

  describe "#on_send" do
    context "with a legacy transform syntax" do
      it 'registers and correct a offenses' do
        expect_offense(<<~RUBY)
          schema do |s|
            {
              required: {
                created_at: s.from.string.to(Time),
                            ^^^^^^^^^^^^^^^^^^^^^^ Calling `s.from.string.to(Time)` without specifying the timezone [...]
              },
              optional: {
                updated_at: s.from.string.to(Time),
                            ^^^^^^^^^^^^^^^^^^^^^^ Calling `s.from.string.to(Time)` without specifying the timezone [...]
              }
            }
          end
        RUBY

        expect_correction(<<~RUBY)
          schema do |s|
            {
              required: {
                created_at: s.from.string.to(Time).using(:utc),
              },
              optional: {
                updated_at: s.from.string.to(Time).using(:utc),
              }
            }
          end
        RUBY
      end
    end

    context "with a good transform syntax" do
      it 'has no offenses' do
        expect_no_offenses(<<~RUBY)
          schema do |s|
            {
              required: {
                created_at: s.from.string.to(Time).using(:utc),
              }
            }
          end
        RUBY
      end
    end
  end
end
