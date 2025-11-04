# frozen_string_literal: true

require_relative "lib/alchemrest/version"

Gem::Specification.new do |spec|
  spec.name = "alchemrest"
  spec.version = Alchemrest::VERSION
  spec.authors = ["Andrew Swerlick", "James Boyer"]
  spec.email = ["andrew.swerlick@betterment.com", "james.boyer@betterment.com"]

  spec.summary = %(
    A tool to help you transform third party api's into a set of classes and models
    designed to work nicely with your domain."
  )
  spec.homepage = "https://github.com/Betterment/alchemrest"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Betterment/alchemrest"
  spec.metadata["changelog_uri"] = "https://github.com/Betterment/alchemrest/CHANGELOG.md"
  spec.metadata['allowed_push_host'] = 'http://rubygems.org'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  rails_constraints = [">= 7.2", "< 8.1"]

  spec.add_dependency 'activerecord', rails_constraints
  spec.add_dependency 'activesupport', rails_constraints
  spec.add_dependency "circuitbox", "~> 2.0.0"
  spec.add_dependency "faraday", ">= 1.10", "< 3.0"
  spec.add_dependency "memosa", ">= 0.8.2"
  spec.add_dependency 'money', '>= 6.0'
  spec.add_dependency 'morpher', '>=0.4.1'
  spec.add_dependency 'multi_json', '~> 1.0'
  spec.add_dependency 'mustermann-contrib', '>= 1.0'
  spec.add_dependency 'railties', rails_constraints
  spec.add_dependency 'sentry-ruby'
  spec.add_dependency 'sorbet-runtime', '>= 0.5.0'

  spec.add_development_dependency "activemodel"
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency "betterlint"
  spec.add_development_dependency 'combustion'
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "moneta"
  spec.add_development_dependency 'mutant-rspec', '~> 0.13.4'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency "pry"
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'tapioca', '>= 0.16.6'
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
