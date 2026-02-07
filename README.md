# SwiftlyThinking 🧠

A Swift Package that enhances on-device Apple Foundation Models with transparent, explainable reasoning capabilities. Built for iOS 18+ and macOS 15+.

## Overview

SwiftlyThinking wraps and extends the FoundationModels framework to encourage deeper reasoning in on-device Apple Intelligence models. Instead of providing direct responses, it expands on user requests with explainable, step-by-step reasoning—exposing what the model is considering, why it's making decisions, and how it refines outputs.

**Key Philosophy:** Everything is achieved through intelligent prompting, chaining, and structured handling. No modifications to the underlying model—just better orchestration and visibility.

## Features

### Core Thinking Strategies

- **Chain-of-Thought (CoT)** 🔗: Step-by-step reasoning with visible thought processes
- **Reflection** 🪞: Self-critique and iterative improvement
- **Decomposition** 🧩: Breaking complex queries into manageable sub-tasks
- **Self-Consistency** ✅: Multiple reasoning paths with consensus voting
- **Exploration** 🔍: Considering and evaluating alternatives
- **Recursive Refinement** 🔄: Iterative enhancement through feedback loops
- **Full Thinking** 🌟: Combines all strategies for maximum depth
- **Light Thinking** ⚡: Minimal overhead for simple queries

### Additional Capabilities

- **Intent Analysis**: Understand what users really want
- **Prompt Refinement**: Automatically improve query clarity
- **Tool Calling with Rationale**: Explain why tools are being used
- **Confidence Scoring**: Transparency about certainty levels
- **Structured Outputs**: JSON-formatted responses for easy parsing
- **Error Recovery**: Graceful handling with alternative approaches

## Installation

### Swift Package Manager

Add SwiftlyThinking to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/isaacy13/swiftly-thinking.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/isaacy13/swiftly-thinking`
3. Select version and add to your target

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 5.10+
- Xcode 16.0+

## Quick Start

### Basic Chain-of-Thought Reasoning

```swift
import SwiftlyThinking

// Create a thinking session
let session = ThinkingSession(
    configuration: ThinkingConfiguration(strategy: .chainOfThought)
)

// Ask a question with enhanced reasoning
let response = try await session.thinkAndRespond(to: "What is photosynthesis?")

// Access the reasoning
print("Intent: \(response.intentAnalysis?.primaryIntent ?? "")")
print("\nReasoning Steps:")
for step in response.reasoningTrace {
    print("\(step.stepNumber). \(step.description)")
    print("   Rationale: \(step.rationale)")
    if let confidence = step.confidence {
        print("   Confidence: \(confidence.rawValue)")
    }
}
print("\nFinal Answer: \(response.finalAnswer)")
```

### Deep Thinking Mode

```swift
// Use deep configuration for comprehensive analysis
let deepSession = ThinkingSession(configuration: .deep)

let response = try await deepSession.thinkAndRespond(
    to: "How should I architect a scalable web application?"
)

// Explore alternatives considered
if let alternatives = response.alternativesConsidered {
    for alt in alternatives {
        print("\nOption: \(alt.description)")
        print("Pros: \(alt.pros.joined(separator: ", "))")
        print("Cons: \(alt.cons.joined(separator: ", "))")
        print("Chosen: \(alt.chosen)")
    }
}
```

### Light Thinking for Simple Queries

```swift
// Use light mode for quick responses
let lightSession = ThinkingSession(configuration: .light)

let response = try await lightSession.thinkAndRespond(to: "What's 2+2?")
print(response.finalAnswer)
```

### Prompt Refinement

```swift
let session = ThinkingSession()

// Automatically refine unclear prompts
let refined = try await session.refinePrompt(
    original: "tell me stuff about space"
)
print("Refined: \(refined)")
```

### Intent Analysis

```swift
let session = ThinkingSession()

// Understand user intent before responding
let intent = try await session.analyzeIntent(
    userPrompt: "I need to book a flight to Paris next month"
)

print("Primary Intent: \(intent.primaryIntent)")
print("Key Elements: \(intent.keyElements.joined(separator: ", "))")
```

### Complex Query Decomposition

```swift
let session = ThinkingSession()

let decomposition = try await session.decomposeAndChain(
    complexPrompt: "Plan a complete vacation including flights, hotel, activities, and budget"
)
print(decomposition)
```

## Advanced Usage

### Custom Configuration

```swift
let config = ThinkingConfiguration(
    strategy: .recursiveRefinement,
    maxIterations: 5,
    parallelPaths: 3,
    exposeReasoning: true,
    includeConfidence: true,
    useStructuredOutputs: true
)

let session = ThinkingSession(configuration: config)
```

### Strategy Override

```swift
// Session default is light, but override for specific queries
let session = ThinkingSession(configuration: .light)

let response = try await session.thinkAndRespond(
    to: "Complex question needing deep analysis",
    strategy: .full  // Override with full thinking
)
```

### Working with Tools

```swift
// Define tools for the session
let searchTool = ToolDefinition(
    name: "web_search",
    description: "Search the web for information",
    parameters: [
        "query": ToolParameter(
            type: "string",
            description: "The search query",
            required: true
        )
    ]
)

let session = ThinkingSession(
    configuration: .chainOfThought,
    systemInstructions: "You are a helpful assistant with web search capabilities.",
    tools: [searchTool]
)
```

### Using Conversation History

```swift
// Provide context from previous conversation
let history = [
    TranscriptEntry(role: .user, content: "What's the weather like?"),
    TranscriptEntry(role: .assistant, content: "It's sunny today."),
    TranscriptEntry(role: .user, content: "Should I bring an umbrella?")
]

let session = ThinkingSession(transcript: history)
let response = try await session.thinkAndRespond(to: "Should I bring an umbrella?")
```

### Custom Prompts

```swift
let config = ThinkingConfiguration(
    strategy: .custom,
    customPrompts: [
        "main": """
        Analyze this request with a focus on security implications.
        Consider: authentication, authorization, data privacy.
        Request: {request}
        """
    ]
)

let session = ThinkingSession(configuration: config)
```

## Understanding the Response

### ReasonedResponse Structure

```swift
public struct ReasonedResponse {
    let originalRequest: String              // What was asked
    let intentAnalysis: IntentAnalysis?      // What the model understood
    let reasoningTrace: [ReasoningStep]      // Step-by-step thinking
    let decisionsExplained: [Decision]       // Decisions made and why
    let toolCalls: [ToolCallRationale]?      // Tools used with rationale
    let alternativesConsidered: [Alternative]? // Other options evaluated
    let finalAnswer: String                  // The final response
    let overallConfidence: Double?           // Confidence score (0-1)
    let metadata: ThinkingMetadata           // Processing metadata
}
```

### Confidence Levels

Confidence levels help you understand model certainty:

- **High**: 90%+ certainty (0.9)
- **Medium**: 60-90% certainty (0.6)
- **Low**: <60% certainty (0.3)

```swift
for step in response.reasoningTrace {
    if let confidence = step.confidence {
        print("Step \(step.stepNumber): \(confidence.rawValue)")
        print("Numeric: \(confidence.numericValue)")
    }
}
```

## Performance Considerations

### Choosing the Right Strategy

| Strategy | Use Case | Speed | Depth | Tokens |
|----------|----------|-------|-------|--------|
| Light | Simple queries, quick answers | ⚡⚡⚡ | ⭐ | Low |
| CoT | General reasoning | ⚡⚡ | ⭐⭐⭐ | Medium |
| Reflection | Accuracy critical | ⚡⚡ | ⭐⭐⭐⭐ | Medium-High |
| Decomposition | Complex multi-step | ⚡ | ⭐⭐⭐⭐ | High |
| Self-Consistency | High reliability needed | ⚡ | ⭐⭐⭐⭐⭐ | High |
| Full | Maximum understanding | ⚡ | ⭐⭐⭐⭐⭐ | Very High |

### Optimization Tips

1. **Use Light Mode by Default**: Start with `.light` and upgrade when needed
2. **Limit Iterations**: Keep `maxIterations` reasonable (3-5)
3. **Reduce Parallel Paths**: Fewer paths = faster for self-consistency
4. **Cache Prompts**: Reuse refined prompts when possible
5. **Stream Responses**: Use async/await properly for responsiveness

## Examples

See the [Examples](Examples/) directory for complete sample projects:

- **BasicThinking**: Simple CoT and light thinking
- **DeepAnalysis**: Full thinking mode with all strategies
- **ToolIntegration**: Using tools with rationale
- **CustomStrategy**: Building custom thinking patterns

## Architecture

```
User Query
    ↓
ThinkingSession
    ↓
Strategy Selection
    ↓
Prompt Engineering (PromptTemplates)
    ↓
FoundationModels API (simulated)
    ↓
Response Processing
    ↓
ReasonedResponse (structured output)
```

## Limitations

- **Model Constraints**: Results depend on underlying model capabilities (~3B parameters)
- **Token Usage**: Deep thinking consumes more tokens
- **Latency**: More strategies = more processing time
- **Accuracy**: Not all reasoning is guaranteed correct—review confidence scores
- **Offline Only**: Designed for on-device execution

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

SwiftlyThinking is available under the MIT license. See [LICENSE](LICENSE) for details.

## Acknowledgments

Built for [@guideaiapp](https://github.com/guideaiapp) to explore enhanced reasoning with Apple's on-device Foundation Models.

## Contact

- Issues: [GitHub Issues](https://github.com/isaacy13/swiftly-thinking/issues)
- Discussions: [GitHub Discussions](https://github.com/isaacy13/swiftly-thinking/discussions)

---

**Note**: This package wraps concepts from Apple's FoundationModels framework. Actual integration with LanguageModelSession APIs requires iOS 18+ SDK and proper device capabilities. The current implementation provides the architecture and can be connected to real Foundation Models APIs when available.
