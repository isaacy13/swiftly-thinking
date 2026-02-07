# SwiftlyThinking Examples

This directory contains example code demonstrating various features of the SwiftlyThinking package.

## Basic Examples

### 1. Simple Chain-of-Thought

```swift
import SwiftlyThinking

// Create a session with chain-of-thought reasoning
let session = ThinkingSession(
    configuration: ThinkingConfiguration(strategy: .chainOfThought)
)

// Ask a question
let response = try await session.thinkAndRespond(to: "What is photosynthesis?")

// Access the reasoning
print("Reasoning Steps:")
for step in response.reasoningTrace {
    print("\(step.stepNumber). \(step.description)")
    print("   Rationale: \(step.rationale)")
}

print("\nFinal Answer: \(response.finalAnswer)")
```

### 2. Light Thinking Mode

```swift
import SwiftlyThinking

// Use light mode for quick responses
let session = ThinkingSession(configuration: .light)

let response = try await session.thinkAndRespond(to: "What's 2+2?")
print(response.finalAnswer)
```

### 3. Deep Thinking Mode

```swift
import SwiftlyThinking

// Use deep configuration for comprehensive analysis
let session = ThinkingSession(configuration: .deep)

let response = try await session.thinkAndRespond(
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

## Advanced Examples

### 4. Intent Analysis

```swift
import SwiftlyThinking

let session = ThinkingSession()

// Analyze user intent before responding
let intent = try await session.analyzeIntent(
    userPrompt: "I need to book a flight to Paris next month"
)

print("Primary Intent: \(intent.primaryIntent)")
print("Key Elements: \(intent.keyElements.joined(separator: ", "))")
if let ambiguities = intent.ambiguities {
    print("Ambiguities: \(ambiguities.joined(separator: ", "))")
}
```

### 5. Prompt Refinement

```swift
import SwiftlyThinking

let session = ThinkingSession()

// Automatically refine unclear prompts
let refined = try await session.refinePrompt(
    original: "tell me stuff about space"
)
print("Original: tell me stuff about space")
print("Refined: \(refined)")
```

### 6. Complex Query Decomposition

```swift
import SwiftlyThinking

let session = ThinkingSession()

let decomposition = try await session.decomposeAndChain(
    complexPrompt: "Plan a complete vacation including flights, hotel, activities, and budget"
)
print(decomposition)
```

### 7. Self-Consistency Mode

```swift
import SwiftlyThinking

// Generate multiple reasoning paths and vote
let session = ThinkingSession(
    configuration: ThinkingConfiguration(
        strategy: .selfConsistency,
        parallelPaths: 5
    )
)

let response = try await session.thinkAndRespond(
    to: "What is the capital of Australia?"
)

print("Strategy: \(response.metadata.strategy)")
print("Parallel Paths: \(response.metadata.parallelPaths ?? 0)")
print("Answer: \(response.finalAnswer)")
```

### 8. Recursive Refinement

```swift
import SwiftlyThinking

// Iteratively refine the response
let session = ThinkingSession(
    configuration: ThinkingConfiguration(
        strategy: .recursiveRefinement,
        maxIterations: 5
    )
)

let response = try await session.thinkAndRespond(
    to: "Write a professional email to decline a job offer"
)

print("Iterations: \(response.metadata.iterations)")
print("Final Answer: \(response.finalAnswer)")
```

### 9. Custom Configuration

```swift
import SwiftlyThinking

// Create a custom configuration
let config = ThinkingConfiguration(
    strategy: .reflection,
    maxIterations: 3,
    parallelPaths: 1,
    exposeReasoning: true,
    includeConfidence: true,
    useStructuredOutputs: true
)

let session = ThinkingSession(configuration: config)

let response = try await session.thinkAndRespond(
    to: "Explain quantum entanglement"
)

// Access confidence levels
for step in response.reasoningTrace {
    if let confidence = step.confidence {
        print("Step \(step.stepNumber): \(confidence.rawValue) (\(confidence.numericValue))")
    }
}
```

### 10. Strategy Override

```swift
import SwiftlyThinking

// Session default is light, but override for specific queries
let session = ThinkingSession(configuration: .light)

// Use light thinking for simple questions
let simpleResponse = try await session.thinkAndRespond(to: "What's the weather?")

// Override with full thinking for complex questions
let complexResponse = try await session.thinkAndRespond(
    to: "Explain the implications of quantum computing",
    strategy: .full  // Override with full thinking
)

print("Simple strategy: \(simpleResponse.metadata.strategy)")
print("Complex strategy: \(complexResponse.metadata.strategy)")
```

### 11. Working with Tools

```swift
import SwiftlyThinking

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

let weatherTool = ToolDefinition(
    name: "get_weather",
    description: "Get current weather for a location",
    parameters: [
        "location": ToolParameter(
            type: "string",
            description: "City name",
            required: true
        )
    ]
)

let session = ThinkingSession(
    configuration: .chainOfThought,
    systemInstructions: "You are a helpful assistant with web search and weather capabilities.",
    tools: [searchTool, weatherTool]
)

let response = try await session.thinkAndRespond(
    to: "What's the weather in New York?"
)

// Check if tools were considered
if let toolCalls = response.toolCalls {
    for call in toolCalls {
        print("Tool: \(call.toolName)")
        print("Reasoning: \(call.reasoning)")
        print("Expected: \(call.expectedOutcome)")
    }
}
```

### 12. Using Conversation History

```swift
import SwiftlyThinking

// Provide context from previous conversation
let history = [
    TranscriptEntry(role: .user, content: "What's the weather like?"),
    TranscriptEntry(role: .assistant, content: "It's sunny and 75°F today."),
    TranscriptEntry(role: .user, content: "Should I bring an umbrella?")
]

let session = ThinkingSession(
    configuration: .chainOfThought,
    transcript: history
)

let response = try await session.thinkAndRespond(
    to: "Should I bring an umbrella?"
)

print(response.finalAnswer)
```

### 13. JSON Output Parsing

```swift
import SwiftlyThinking

let session = ThinkingSession(
    configuration: ThinkingConfiguration(
        strategy: .chainOfThought,
        useStructuredOutputs: true
    )
)

let response = try await session.thinkAndRespond(
    to: "Analyze the pros and cons of electric vehicles"
)

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let jsonData = try encoder.encode(response)
let jsonString = String(data: jsonData, encoding: .utf8)!

print("JSON Response:")
print(jsonString)
```

### 14. Error Handling

```swift
import SwiftlyThinking

let session = ThinkingSession()

do {
    let response = try await session.thinkAndRespond(
        to: "Complex query that might fail"
    )
    
    // Check for errors in metadata
    if let errors = response.metadata.errors {
        print("Warnings/Errors during processing:")
        for error in errors {
            print("- \(error)")
        }
    }
    
    print("Answer: \(response.finalAnswer)")
} catch {
    print("Error: \(error)")
}
```

### 15. Performance Monitoring

```swift
import SwiftlyThinking

let session = ThinkingSession(configuration: .deep)

let response = try await session.thinkAndRespond(
    to: "Explain machine learning"
)

// Check performance metrics
print("Processing time: \(response.metadata.processingTime ?? 0) seconds")
print("Iterations: \(response.metadata.iterations)")
print("Parallel paths: \(response.metadata.parallelPaths ?? 0)")
print("Overall confidence: \(response.overallConfidence ?? 0)")
```

## Running Examples

To run these examples in your own project:

1. Add SwiftlyThinking as a dependency
2. Create a new Swift file with the example code
3. Import SwiftlyThinking
4. Run the example with `swift run` or in Xcode

## Notes

- These examples use simulated responses since they're not connected to a real FoundationModels API
- In production, the responses would come from the actual on-device model
- All examples demonstrate the API and structure that can be connected to real Foundation Models
