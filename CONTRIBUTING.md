# Contributing to SwiftlyThinking

Thank you for your interest in contributing to SwiftlyThinking! This document provides guidelines for contributing to the project.

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to create a welcoming environment for everyone.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Your environment (iOS/macOS version, Swift version, Xcode version)
- Code samples if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please open an issue with:
- A clear description of the enhancement
- Why this enhancement would be useful
- Example use cases
- Proposed API (if applicable)

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes**:
   - Follow the existing code style
   - Add tests for new features
   - Update documentation as needed
   - Ensure all tests pass
3. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Reference issues in commit messages when applicable
4. **Push to your fork** and submit a pull request

#### PR Guidelines

- Keep PRs focused on a single feature or fix
- Write clear descriptions explaining what changed and why
- Include tests for new functionality
- Update README.md or documentation if needed
- Ensure CI passes before requesting review

## Development Setup

```bash
# Clone the repository
git clone https://github.com/isaacy13/swiftly-thinking.git
cd swiftly-thinking

# Build the package
swift build

# Run tests
swift test
```

## Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions focused and reasonably sized
- Use `async`/`await` for asynchronous operations
- Ensure all types conform to `Sendable` where appropriate

### Documentation

Public APIs should have documentation comments:

```swift
/// Brief description of the function
///
/// Longer description explaining what it does,
/// when to use it, and any important details.
///
/// - Parameters:
///   - param1: Description of param1
///   - param2: Description of param2
/// - Returns: Description of return value
/// - Throws: Description of errors thrown
public func myFunction(param1: String, param2: Int) async throws -> Result {
    // Implementation
}
```

## Testing

- Write tests for all new features
- Ensure existing tests still pass
- Aim for good test coverage
- Test both success and failure cases
- Use descriptive test names

```swift
func testFeatureName_whenCondition_expectedBehavior() {
    // Arrange
    let input = ...
    
    // Act
    let result = ...
    
    // Assert
    XCTAssertEqual(result, expected)
}
```

## Adding New Strategies

If you want to add a new thinking strategy:

1. Add the strategy to the `ThinkingStrategy` enum
2. Implement the strategy method in `ThinkingSession`
3. Add corresponding prompt templates to `PromptTemplates`
4. Write tests for the new strategy
5. Update README.md with usage examples
6. Document when the strategy should be used

## Areas for Contribution

Some areas where contributions would be particularly welcome:

### Core Features
- Real FoundationModels API integration (when available)
- Additional thinking strategies
- Enhanced error recovery mechanisms
- Performance optimizations
- Streaming responses

### Tools & Utilities
- More prompt templates
- Helper functions for common tasks
- Visualization tools for reasoning traces
- Export/import for configurations

### Documentation
- More usage examples
- Tutorial articles
- Video demonstrations
- API reference improvements

### Testing
- More comprehensive test coverage
- Performance benchmarks
- Integration tests
- Example projects

## Questions?

If you have questions about contributing, feel free to:
- Open a discussion on GitHub
- Ask in an issue
- Reach out to the maintainers

## License

By contributing to SwiftlyThinking, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions help make SwiftlyThinking better for everyone. Thank you for taking the time to contribute!
