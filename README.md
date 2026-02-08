# swiftly-thinking

`swiftly-thinking` is an experimental Swift Package for @guideaiapp that wraps Apple’s `FoundationModels` framework and encourages on-device models to “think” more deliberately. It focuses on visibility and explainability by chaining prompts, exposing intent analysis, and surfacing reflection steps before the final answer.

## Requirements

- iOS 26+, macOS 15+, visionOS 26+
- Swift 5.10+
- Apple Intelligence enabled on supported hardware

## Installation

Add the package to your project in Xcode or via `Package.swift`:

```swift
.package(url: "https://github.com/isaacy13/swiftly-thinking", from: "0.1.0")
```

Then import the module:

```swift
import SwiftlyThinking
```

## Quick Start

```swift
import FoundationModels
import SwiftlyThinking

@available(iOS 26, macOS 15, visionOS 26, *)
func runThinkingSession() async throws {
    let session = LanguageModelSession(instructions: "Be concise, but show your reasoning.")
    var thinkingSession = ThinkingSession(session: session)

    let response = try await thinkingSession.thinkAndRespond(
        to: "Summarize the pros and cons of using on-device models."
    )

    print(response.intentAnalysis)
    print(response.reasoningTrace.joined(separator: "\n"))
    print(response.finalAnswer)
}
```

## Guided Generation

SwiftlyThinking leverages FoundationModels guided generation. Any `@Generable` type can be requested directly:

```swift
import FoundationModels
import SwiftlyThinking

@Generable
struct ChecklistItem: Codable {
    let title: String
    let completed: Bool
}

@available(iOS 26, macOS 15, visionOS 26, *)
func generateChecklist() async throws {
    let session = LanguageModelSession()
    var thinking = ThinkingSession(session: session)
    let item = try await thinking.respond(to: "Create a checklist item.", outputType: ChecklistItem.self)
    print(item)
}
```

## Strategies

Choose a strategy to control how much reasoning is exposed:

```swift
var thinkingSession = ThinkingSession(
    options: ThinkingOptions(strategy: .full, mode: .deep, selfConsistencySamples: 3),
    respond: { prompt, _ in
        // Bridge to your LanguageModelSession or mock implementation
        return "{\"intent_analysis\":\"...\",\"reasoning_trace\":[\"...\"],\"decisions_explained\":[\"...\"],\"final_answer\":\"...\",\"confidence\":\"high\"}"
    }
)
```

- `.cot` — default chain-of-thought exposure with intent analysis.
- `.reflection` — adds self-critique and revision loops.
- `.decomposition` — breaks complex prompts into sub-steps and recombines.
- `.full` — enables refinement, alternatives, decomposition, reflection, and self-consistency voting.
- `.light` — shorter explanations for low-latency usage.

## Streaming

Stream partial updates with `thinkAndRespondStream`:

```swift
var thinking = ThinkingSession(options: ThinkingOptions(streamReasoning: true))
let response = try await thinking.thinkAndRespondStream(
    to: "Draft a product brief.",
    onTranscriptUpdate: { entry in
        print("Transcript update:", entry.content)
    },
    onReasoningUpdate: { entry in
        print("Reasoning update:", entry.content)
    }
)
```

## Tool Execution & Logs

Register executable tools with async handlers. The session executes tool calls, injects results into the transcript, and continues:

```swift
struct LookupInput: Codable { let query: String }
struct LookupOutput: Codable { let result: String }

let tool = ExecutableTool(name: "lookup", description: "Search local data") { (input: LookupInput) async throws -> LookupOutput in
    LookupOutput(result: "Found \\(input.query)")
}

var thinking = ThinkingSession(executableTools: [tool])
let response = try await thinking.thinkAndRespond(to: "Lookup SwiftlyThinking.")
```

The transcript includes tool outputs and reasoning notes for auditability.

## Notes

- This package does **not** modify the underlying model. All reasoning features are achieved through prompt chaining and session orchestration.
- Keep strategies lightweight for short prompts to avoid unnecessary latency.
- FoundationModels APIs are only available on supported Apple platforms; use the closure-based initializer for unit testing or server-side mocks.

## License

MIT License. See [LICENSE](LICENSE).
