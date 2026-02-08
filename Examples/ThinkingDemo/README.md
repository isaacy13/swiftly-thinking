# ThinkingDemo

A runnable command-line demo application that showcases the SwiftlyThinking package capabilities.

## Overview

This example demonstrates all major features of SwiftlyThinking:

1. **Chain-of-Thought Reasoning** - Step-by-step reasoning with visible thought processes
2. **Light vs Deep Thinking** - Comparing lightweight and comprehensive thinking modes
3. **Self-Consistency** - Multiple reasoning paths with consensus voting
4. **Intent Analysis** - Understanding user intent before responding
5. **Alternative Exploration** - Evaluating different approaches with pros/cons
6. **JSON Serialization** - Serializing and deserializing responses

## Requirements

- Swift 6.0+
- iOS 26+ / macOS 26+ (Foundation Models requirement)

## Building and Running

### From Command Line

```bash
cd Examples/ThinkingDemo
swift run
```

### From Xcode

1. Open `Package.swift` in Xcode
2. Select the ThinkingDemo scheme
3. Click Run (or press Cmd+R)

## Expected Output

The demo will run through 6 different scenarios, showing:

- Reasoning traces with confidence levels
- Performance metrics (iterations, processing time)
- Intent analysis results
- Alternative evaluation with pros/cons
- JSON serialization/deserialization

Example output:

```
🧠 SwiftlyThinking Demo
==================================================

📝 Demo 1: Chain-of-Thought Reasoning
--------------------------------------------------
Question: What is the Fibonacci sequence?

Reasoning Steps:
  1. Analyze the user's request
     Rationale: First, I need to understand what's being asked
     Confidence: High (0.9)
  2. Consider relevant information
     Rationale: Gather facts and knowledge needed to respond
     Confidence: High (0.9)
  3. Formulate response
     Rationale: Synthesize information into a clear answer
     Confidence: Medium (0.6)

Answer: Response generated through chain-of-thought reasoning for: What is the Fibonacci sequence?
Overall Confidence: 0.85

...
```

## Code Structure

- `main.swift` - Main demo application with 6 example scenarios
- `Package.swift` - Swift Package manifest with SwiftlyThinking dependency

## What It Demonstrates

### Chain-of-Thought
Shows how the model breaks down reasoning into explicit steps with confidence levels.

### Light vs Deep Thinking
Compares the performance and output differences between lightweight (quick responses) and deep thinking (comprehensive analysis) modes.

### Self-Consistency
Demonstrates generating multiple independent reasoning paths and selecting the most consistent answer.

### Intent Analysis
Shows how the package analyzes user queries to understand intent, key elements, and ambiguities before responding.

### Alternative Exploration
Illustrates evaluating multiple approaches with explicit pros/cons analysis before making a decision.

### JSON Serialization
Validates that all data structures can be serialized to/from JSON for storage or transmission.

## Customization

You can modify `main.swift` to:

- Change the questions being asked
- Adjust thinking strategies
- Modify configuration parameters (iterations, parallel paths, etc.)
- Add your own custom demonstrations

## Notes

- This demo uses simulated responses since it's not connected to a real FoundationModels API
- The structure and API demonstrated here is ready for integration with real Foundation Models
- All timing and confidence metrics are generated for demonstration purposes
- In production, connect to the actual FoundationModels framework on iOS 26+ / macOS 26+ devices

## Related

- See [Examples/README.md](../README.md) for more code snippets
- See main [README.md](../../README.md) for full package documentation
