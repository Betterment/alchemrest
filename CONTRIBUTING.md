# Contributing to AlchemREST

Thank you for your interest in contributing to AlchemREST!

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](./CODE_OF_CONDUCT.md) By participating in this project you agree to abide by its terms.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Install dependencies with `bundle install`
4. Run the test suite with `bundle exec rspec` to ensure everything is working
5. Create a new branch for your feature or bug fix

## Development Setup

### Prerequisites

- Ruby (see `.ruby-version` for the required version)
- Bundler

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run a specific test file
bundle exec rspec spec/path/to/spec.rb

# Run tests with different Rails versions
bundle exec appraisal rspec
```

### Code Quality Tools

```bash
# Run RuboCop for linting
bundle exec rubocop

# Auto-fix RuboCop violations
bundle exec rubocop -a

# Type check examples with Sorbet
./bin/typecheck

# Run all checks (linting + tests)
bundle exec rake
```

## Using Mutant for Mutation Testing

AlchemREST uses [Mutant](https://github.com/mbj/mutant) for mutation testing to ensure high-quality test coverage. Mutant is free for open source projects.

### What is Mutation Testing?

Mutation testing verifies that your tests actually catch bugs by introducing small changes ("mutations") to the code and checking if tests fail. If tests still pass after a mutation, it indicates missing test coverage.

### Running Mutation Tests

```bash
# Run mutation tests with formatted output
./bin/mutant-check
```

This runs `bundle exec mutant run --since origin/main --fail-fast` and formats the output for readability.

### Interpreting Mutation Test Results

When a mutation is found, you'll see output like:

```
Mutation Found
++++++++++++++++++++++
Alchemrest::HttpRequest#handle_error:file.rb:65:c3e2e
-----------------------
@@ -1,10 +1,10 @@
 def handle_error(error)
-  if error.wrapped_exception.is_a?(Net::OpenTimeout)
+  if error.wrapped_exception.instance_of?(Net::OpenTimeout)
     Result.Error(TimeoutError.new)
   else
     raise(RequestFailedError)
   end
 end
```

### Responding to Uncovered Mutations

You have two options:

1. **Accept the mutation**: If the mutated code preserves intended behavior and improves code quality, update your code to match the mutation.

2. **Write a test**: If the mutation would break intended behavior, write a test that fails with the mutated code, proving the original is necessary.

Example: For `is_a?` vs `instance_of?`:
- If inheritance matters, write a test with a subclass to prove `is_a?` is correct
- If only exact type matching is needed, accept the mutation and use `instance_of?`

## Submitting Changes

### Pull Request Process

1. **Before starting work on a feature**:
   - Check existing issues and pull requests to avoid duplicate work
   - For new features, open an issue first to discuss the idea
   - For bug fixes, ensure the bug is confirmed

2. **While developing**:
   - Add tests for any new functionality
   - Update documentation as needed
   - Update sorbet type definitions
   - Follow existing code style and conventions
   - Ensure all tests pass locally
   - Run mutation tests with `./bin/mutant-check`
   - Type check examples with `./bin/typecheck`

3. **Submitting the PR**:
   - Update the CHANGELOG.md with your changes
   - Use a [semantic PR title](https://pulsar.apache.org/contribute/develop-semantic-title/) 
   - Write a clear PR description explaining the what and why
   - Reference any related issues
   - Ensure CI passes

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb in present tense ("Add", "Fix", "Update", etc.)
- Reference issue numbers when applicable

### Version Bumping

We follow [Semantic Versioning](https://semver.org/):
- MAJOR version for incompatible API changes
- MINOR version for backwards-compatible functionality additions
- PATCH version for backwards-compatible bug fixes

Update the version in `lib/alchemrest/version.rb` when appropriate.

## Understanding AlchemREST Architecture

Before contributing, we recommend reading the [Architecture documentation](./docs/architecture-of-alchemrest.md) to understand the codebase structure.

### Key Components

- **Client Layer**: Manages HTTP connections and middleware
- **Request Pipeline**: Root → Request → HttpRequest → Response → Result
- **Data Transformation**: Schema validation and type coercion
- **Response Pipeline**: Modular transformation steps

### Design Patterns

- **Result Monad**: API calls return `Result::Ok` or `Result::Error`
- **Transform Registry**: Extensible type transformation system
- **Factory Pattern**: Request building with sensible defaults

## Testing Guidelines

- Unit tests go in `spec/alchemrest/`
- Integration tests go in `spec/integration/`
- Use shared examples from `spec/support/` when applicable
- Stub external API calls with WebMock
- See `examples/bank_api.rb` for usage patterns

## Documentation

- Update relevant documentation in `docs/` for new features
- Include code examples where helpful
- Keep the README up to date with any new functionality

## Questions?

If you have questions or need help:
- Open an issue for bugs or feature discussions
- Check existing issues and documentation first
- Be as detailed as possible when reporting issues

## License

By contributing to AlchemREST, you agree that your contributions will be licensed under the same license as the project (see LICENSE.txt file).
