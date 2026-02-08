import Foundation
import SwiftlyThinking

@main
struct BasicExample {
    static func main() async throws {
        var session = ThinkingSession(
            options: ThinkingOptions(strategy: .reflection, reasoningRedaction: .summarized),
            respond: { prompt, _ in
                return """
                {"intent_analysis":"Demo intent","reasoning_trace":["Considered the prompt"],"decisions_explained":["Used mock"],"final_answer":"Hello from SwiftlyThinking","confidence":"high"}
                """
            }
        )

        let response = try await session.thinkAndRespond(to: "Say hello")
        print("Final answer:", response.finalAnswer)
        print("Reasoning:", response.reasoningTrace.joined(separator: "\n"))
    }
}
