# frozen_string_literal: true

require_relative "lib/alchemrest/sentry/version"

Gem::Specification.new do |spec|
  spec.name = "alchemrest-sentry"
  spec.version = Alchemrest::Sentry::VERSION
  spec.authors = ["Andrew Swerlick", "James Boyer"]
  spec.email = ["andrew.swerlick@betterment.com", "james.boyer@betterment.com"]

  spec.summary = %(
    An integration between alchemrest and sentry so errors captured by alchemrest
    are surfaced in sentry
  )
  spec.description = %(
    Plugin for alchemrest tht ensures that errors rescued by alchemrest still show up in Sentry alerts
  )
  spec.license = "MIT"

  spec.homepage = "https://github.com/Betterment/alchemrest"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata["changelog_uri"] = "https://github.com/Betterment/alchemrest/CHANGELOG.md"

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

  spec.add_dependency 'alchemrest', '>= 3.0.0-alpha'
  spec.add_dependency 'sentry-ruby'
  spec.add_dependency 'sorbet-runtime', '>= 0.5.0'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency "betterlint", '~> 1.19.0'
  spec.add_development_dependency 'mutant-rspec', '~> 0.13.4'
  spec.add_development_dependency "pry"
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'sorbet'
  spec.add_development_dependency 'tapioca', '>= 0.16.6'
  spec.add_development_dependency "webmock"
end
