# frozen_string_literal: true

require 'rails/railtie'

module Alchemrest
  class Railtie < ::Rails::Railtie
    initializer 'alchemrest.logger' do
      Alchemrest.logger = Rails.logger
    end

    initializer 'alchemrest.configure_parameter_filter' do |app|
      config.after_initialize do
        Alchemrest.filter_parameters += app.config.filter_parameters
      end
    end

    initializer 'alchemrest.deprecator' do |app|
      app.deprecators[:alchemrest] = Alchemrest.deprecator
    end

    initializer 'alchemrest.deprecator.behavior' do |app|
      Alchemrest.deprecator.behavior = app.config.active_support.deprecation
    end
  end
end
