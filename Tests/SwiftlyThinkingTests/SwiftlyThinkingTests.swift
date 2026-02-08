import XCTest
@testable import SwiftlyThinking

final class SwiftlyThinkingTests: XCTestCase {
    actor MockClient: ThinkingSessionClient {
        private var responses: [String]
        private var prompts: [String] = []

        init(responses: [String]) {
            self.responses = responses
        }

        func generateResponse(for prompt: String, configuration: ThinkingSession.Configuration) async throws -> String {
            prompts.append(prompt)
            if responses.isEmpty {
                return ""
            }
            return responses.removeFirst()
        }

        func recordedPrompts() -> [String] {
            prompts
        }
    }

    func testRefinePromptUsesTemplate() async throws {
        let mock = MockClient(responses: ["Refined prompt"]) 
        var session = ThinkingSession(client: mock)
        let refined = try await session.refinePrompt(original: "Make this clear")

        XCTAssertEqual(refined, "Refined prompt")
        let prompts = await mock.recordedPrompts()
        XCTAssertEqual(prompts.count, 1)
        XCTAssertTrue(prompts.first?.contains("Refine this user prompt") == true)
    }

    func testThinkAndRespondParsesStructuredOutput() async throws {
        let structured = """
        {"intent_analysis":"Intent analysis","reasoning_trace":["Step 1"],"decisions_explained":["Decision"],"final_answer":"Final answer","confidence":"high"}
        """
        let mock = MockClient(responses: ["Intent analysis", structured])
        var session = ThinkingSession(options: ThinkingOptions(strategy: .cot), client: mock)
        let response = try await session.thinkAndRespond(to: "Summarize this")

        XCTAssertEqual(response.intentAnalysis, "Intent analysis")
        XCTAssertEqual(response.finalAnswer, "Final answer")
        XCTAssertEqual(response.confidence, .high)
        XCTAssertTrue(response.reasoningTrace.contains("Step 1"))
    }

    func testDecomposeAndChainCombinesResults() async throws {
        let mock = MockClient(responses: [
            "1. Step A\n2. Step B",
            "Result A",
            "Result B",
            "Combined answer"
        ])
        var session = ThinkingSession(options: ThinkingOptions(strategy: .decomposition), client: mock)
        let combined = try await session.decomposeAndChain(complexPrompt: "Complex request")

        XCTAssertTrue(combined.contains("Recombined Answer"))
        XCTAssertTrue(combined.contains("Combined answer"))
    }
}
