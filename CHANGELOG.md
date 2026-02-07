# Changelog

All notable changes to SwiftlyThinking will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-07

### Added
- Initial release of SwiftlyThinking package
- Core `ThinkingSession` API for enhanced reasoning
- Multiple thinking strategies:
  - Chain-of-Thought (CoT) reasoning
  - Reflection and self-critique
  - Query decomposition
  - Self-consistency with voting
  - Alternative exploration
  - Recursive refinement
  - Full thinking mode (combines all strategies)
  - Light thinking mode (minimal overhead)
  - Custom strategy support
- `ReasonedResponse` model with structured reasoning traces
- `IntentAnalysis` for understanding user requests
- `PromptTemplates` with comprehensive prompt engineering templates
- Support for tool calling with rationale
- Confidence scoring for transparency
- Configurable thinking modes (light vs deep)
- Conversation history support via `TranscriptEntry`
- JSON serialization for all data models
- Comprehensive test suite (34 tests)
- Documentation with usage examples
- Support for iOS 17+ and macOS 14+

### Features
- Transparent reasoning with visible thought processes
- Step-by-step decision explanations
- Alternative approach evaluation
- On-device execution focus
- Privacy-preserving design
- Async/await support
- Sendable conformance for concurrency safety
- Extensible prompt templates
- Tool definition support
- Error handling and recovery
- Performance metadata tracking

[1.0.0]: https://github.com/isaacy13/swiftly-thinking/releases/tag/v1.0.0
