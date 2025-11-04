# frozen_string_literal: true

require 'spec_helper'
require 'pry'
require 'combustion'

Combustion.initialize! :action_controller, :active_record do
  config.filter_parameters += %i(foo bar token)
  config.active_support.deprecation = :raise
end
