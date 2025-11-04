# frozen_string_literal: true

require "rubygems"
require "bundler"
require 'combustion'
require_relative '../../../examples/bank_api'

Bundler.require :default, :development

Combustion.initialize! :action_controller, :active_record
