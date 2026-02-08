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

    struct ToolInput: Codable, Equatable, Sendable {
        let query: String
    }

    struct ToolOutput: Codable, Equatable, Sendable {
        let result: String
    }

    actor ToolTracker {
        private(set) var executedQuery: String? = nil

        func record(query: String) {
            executedQuery = query
        }
    }

    actor UpdateRecorder {
        private var transcriptEntries: [TranscriptEntry] = []
        private var reasoningEntries: [TranscriptEntry] = []

        func recordTranscript(_ entry: TranscriptEntry) {
            transcriptEntries.append(entry)
        }

        func recordReasoning(_ entry: TranscriptEntry) {
            reasoningEntries.append(entry)
        }

        func transcriptUpdates() -> [TranscriptEntry] {
            transcriptEntries
        }

        func reasoningUpdates() -> [TranscriptEntry] {
            reasoningEntries
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

    func testThinkAndRespondParsesStructuredOutputAndRedacts() async throws {
        let structured = """
        {"intent_analysis":"Intent analysis","reasoning_trace":["Step 1"],"decisions_explained":["Decision"],"final_answer":"Final answer","confidence":"high"}
        """
        let mock = MockClient(responses: ["Intent analysis", structured])
        var session = ThinkingSession(options: ThinkingOptions(strategy: .cot), client: mock)
        let response = try await session.thinkAndRespond(to: "Summarize this")

        XCTAssertEqual(response.intentAnalysis, "Intent analysis")
        XCTAssertEqual(response.finalAnswer, "Final answer")
        XCTAssertEqual(response.confidence, .high)
        XCTAssertEqual(response.reasoningTrace.first, "Reasoning redacted.")
    }

    func testReflectionCritiqueAndRevisedAnswer() async throws {
        let structured = """
        {"intent_analysis":"Intent analysis","reasoning_trace":["Draft reasoning"],"decisions_explained":["Decision"],"final_answer":"Draft answer","confidence":"medium"}
        """
        let reflection = """
        {"critique":"Needs more detail","revised_answer":"Revised answer"}
        """
        let mock = MockClient(responses: ["Intent analysis", structured, reflection])
        var session = ThinkingSession(
            options: ThinkingOptions(strategy: .reflection, maxRefinementIterations: 1, reasoningRedaction: .full),
            client: mock
        )
        let response = try await session.thinkAndRespond(to: "Explain X")

        XCTAssertEqual(response.reflectionCritique, "Needs more detail")
        XCTAssertEqual(response.reflectionRevised, "Revised answer")
        XCTAssertEqual(response.finalAnswer, "Revised answer")
    }

    func testToolExecutionRunsHandler() async throws {
        let toolCall = """
        {"tool":"search","arguments":{"query":"swift"}}
        """
        let structured = """
        {"intent_analysis":"Intent","reasoning_trace":["Step"],"decisions_explained":["Decision"],"final_answer":"Tool result used","confidence":"low"}
        """
        let mock = MockClient(responses: ["Intent", toolCall, structured])
        let tracker = ToolTracker()
        let tool = ExecutableTool(name: "search", description: "Lookup data") { (input: ToolInput) async throws -> ToolOutput in
            await tracker.record(query: input.query)
            return ToolOutput(result: "Found \(input.query)")
        }
        var session = ThinkingSession(
            configuration: ThinkingSession.Configuration(tools: []),
            options: ThinkingOptions(strategy: .intentOnly, reasoningRedaction: .full),
            prompts: .default,
            executableTools: [tool],
            client: mock
        )

        let response = try await session.thinkAndRespond(to: "Find Swift")
        XCTAssertEqual(response.finalAnswer, "Tool result used")
        let executedQuery = await tracker.executedQuery
        XCTAssertEqual(executedQuery, "swift")
        XCTAssertTrue(session.transcript.contains { entry in
            entry.role == .tool && entry.content.contains("Found swift")
        })
    }

    func testStreamingUpdatesTranscriptAndReasoning() async throws {
        let longAnswerLength = 250
        let longAnswer = String(repeating: "A", count: longAnswerLength)
        let structured = """
        {"intent_analysis":"Intent","reasoning_trace":["Sensitive reasoning"],"decisions_explained":["Decision"],"final_answer":"\(longAnswer)","confidence":"high"}
        """
        let mock = MockClient(responses: ["Intent", structured])
        let recorder = UpdateRecorder()
        var session = ThinkingSession(
            options: ThinkingOptions(strategy: .cot, streamReasoning: true),
            client: mock
        )

        let response = try await session.thinkAndRespondStream(
            to: "Stream this",
            onTranscriptUpdate: { entry in
                await recorder.recordTranscript(entry)
            },
            onReasoningUpdate: { entry in
                await recorder.recordReasoning(entry)
            }
        )

        XCTAssertEqual(response.finalAnswer, longAnswer)
        let transcriptUpdates = await recorder.transcriptUpdates()
        let reasoningUpdates = await recorder.reasoningUpdates()
        XCTAssertTrue(transcriptUpdates.count >= 2)
        XCTAssertEqual(transcriptUpdates.first?.role, .user)
        XCTAssertEqual(transcriptUpdates.last?.content, longAnswer)
        XCTAssertTrue(reasoningUpdates.contains { $0.content == "Reasoning redacted." })
    }
}
