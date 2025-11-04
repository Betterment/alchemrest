# frozen_string_literal: true

require 'rails/generators/migration'
require 'rails/generators/active_record'

module Alchemrest
  class KillSwitchMigrationGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_paths << File.join(File.dirname(__FILE__), 'templates')

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number dirname
    end

    def create_migration_file
      migration_template 'kill_switch_migration.rb.erb', "db/migrate/create_alchemrest_kill_switches.rb",
                         migration_version:
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]" if ActiveRecord::VERSION::MAJOR >= 5
    end
  end
end
