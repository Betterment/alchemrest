# frozen_string_literal: true

module Alchemrest
  module FactoryBot
    def self.enable!
      ::FactoryBot.register_strategy(:alchemrest_record_for, Alchemrest::FactoryBot::AlchemrestStrategy)
      ::FactoryBot.register_strategy(:alchemrest_hash_for, Alchemrest::FactoryBot::HashStrategy)

      ::FactoryBot::Syntax::Default::DSL.class_eval do
        include Alchemrest::FactoryBot::Mixins
      end
    end

    class OmitKey
      include Singleton
    end

    module Mixins
      def alchemrest_factory(name, options = {}, &block)
        raise ArgumentError, "You must specify a class" unless options[:class]
        raise ArgumentError, "You must specify a block" unless block

        factory(name, options) do
          skip_create

          initialize_with do
            provided_attributes = attributes.reject { |_, v| v.is_a?(Alchemrest::FactoryBot::OmitKey) }
            options[:class].constantize.from_hash(provided_attributes)
          end

          instance_eval(&block)
        end
      end
    end

    class AlchemrestStrategy
      def association(runner)
        runner.run(:alchemrest_hash_for)
      end

      def result(evaluation)
        evaluation.object
      end

      def to_sym
        :alchemrest_record_for
      end
    end

    class HashStrategy
      def association(runner)
        runner.run(:alchemrest_hash_for)
      end

      def result(evaluation)
        evaluation.hash.reject { |_, v| v.is_a?(Alchemrest::FactoryBot::OmitKey) }
      end

      def to_sym
        :alchemrest_hash_for
      end
    end
  end
end
