import XCTest
@testable import SwiftlyThinking

final class SwiftlyThinkingTests: XCTestCase {
    
    // MARK: - ThinkingStrategy Tests
    
    func testThinkingStrategyRawValues() {
        XCTAssertEqual(ThinkingStrategy.chainOfThought.rawValue, "chain_of_thought")
        XCTAssertEqual(ThinkingStrategy.reflection.rawValue, "reflection")
        XCTAssertEqual(ThinkingStrategy.decomposition.rawValue, "decomposition")
        XCTAssertEqual(ThinkingStrategy.selfConsistency.rawValue, "self_consistency")
        XCTAssertEqual(ThinkingStrategy.exploration.rawValue, "exploration")
        XCTAssertEqual(ThinkingStrategy.recursiveRefinement.rawValue, "recursive_refinement")
        XCTAssertEqual(ThinkingStrategy.full.rawValue, "full")
        XCTAssertEqual(ThinkingStrategy.light.rawValue, "light")
        XCTAssertEqual(ThinkingStrategy.custom.rawValue, "custom")
    }
    
    func testThinkingStrategyEncoding() throws {
        let strategy = ThinkingStrategy.chainOfThought
        let encoded = try JSONEncoder().encode(strategy)
        let decoded = try JSONDecoder().decode(ThinkingStrategy.self, from: encoded)
        XCTAssertEqual(strategy, decoded)
    }
    
    // MARK: - ThinkingConfiguration Tests
    
    func testDefaultConfiguration() {
        let config = ThinkingConfiguration()
        XCTAssertEqual(config.strategy, .chainOfThought)
        XCTAssertEqual(config.maxIterations, 3)
        XCTAssertEqual(config.parallelPaths, 3)
        XCTAssertTrue(config.exposeReasoning)
        XCTAssertTrue(config.includeConfidence)
        XCTAssertTrue(config.useStructuredOutputs)
        XCTAssertNil(config.customPrompts)
    }
    
    func testLightConfiguration() {
        let config = ThinkingConfiguration.light
        XCTAssertEqual(config.strategy, .light)
        XCTAssertEqual(config.maxIterations, 1)
        XCTAssertEqual(config.parallelPaths, 1)
        XCTAssertTrue(config.exposeReasoning)
        XCTAssertFalse(config.includeConfidence)
        XCTAssertFalse(config.useStructuredOutputs)
    }
    
    func testDeepConfiguration() {
        let config = ThinkingConfiguration.deep
        XCTAssertEqual(config.strategy, .full)
        XCTAssertEqual(config.maxIterations, 5)
        XCTAssertEqual(config.parallelPaths, 5)
        XCTAssertTrue(config.exposeReasoning)
        XCTAssertTrue(config.includeConfidence)
        XCTAssertTrue(config.useStructuredOutputs)
    }
    
    // MARK: - ConfidenceLevel Tests
    
    func testConfidenceLevelNumericValues() {
        XCTAssertEqual(ConfidenceLevel.high.numericValue, 0.9)
        XCTAssertEqual(ConfidenceLevel.medium.numericValue, 0.6)
        XCTAssertEqual(ConfidenceLevel.low.numericValue, 0.3)
    }
    
    func testConfidenceLevelEncoding() throws {
        let confidence = ConfidenceLevel.high
        let encoded = try JSONEncoder().encode(confidence)
        let decoded = try JSONDecoder().decode(ConfidenceLevel.self, from: encoded)
        XCTAssertEqual(confidence, decoded)
    }
    
    // MARK: - ReasonedResponse Tests
    
    func testReasonedResponseCreation() {
        let intentAnalysis = IntentAnalysis(
            primaryIntent: "Test intent",
            keyElements: ["element1", "element2"],
            ambiguities: nil,
            confidence: 0.9
        )
        
        let reasoningStep = ReasoningStep(
            stepNumber: 1,
            description: "Test step",
            rationale: "Test rationale",
            confidence: .high,
            details: nil
        )
        
        let decision = Decision(
            decision: "Test decision",
            reasoning: "Test reasoning",
            confidence: .medium
        )
        
        let metadata = ThinkingMetadata(
            strategy: .chainOfThought,
            iterations: 1,
            parallelPaths: nil,
            processingTime: 1.5,
            errors: nil
        )
        
        let response = ReasonedResponse(
            originalRequest: "Test request",
            intentAnalysis: intentAnalysis,
            reasoningTrace: [reasoningStep],
            decisionsExplained: [decision],
            toolCalls: nil,
            alternativesConsidered: nil,
            finalAnswer: "Test answer",
            overallConfidence: 0.85,
            metadata: metadata
        )
        
        XCTAssertEqual(response.originalRequest, "Test request")
        XCTAssertEqual(response.finalAnswer, "Test answer")
        XCTAssertEqual(response.reasoningTrace.count, 1)
        XCTAssertEqual(response.decisionsExplained.count, 1)
        XCTAssertEqual(response.metadata.strategy, .chainOfThought)
    }
    
    func testReasonedResponseEncoding() throws {
        let metadata = ThinkingMetadata(
            strategy: .chainOfThought,
            iterations: 1,
            parallelPaths: nil,
            processingTime: nil,
            errors: nil
        )
        
        let response = ReasonedResponse(
            originalRequest: "Test",
            intentAnalysis: nil,
            reasoningTrace: [],
            decisionsExplained: [],
            toolCalls: nil,
            alternativesConsidered: nil,
            finalAnswer: "Answer",
            overallConfidence: 0.8,
            metadata: metadata
        )
        
        let encoded = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(ReasonedResponse.self, from: encoded)
        
        XCTAssertEqual(decoded.originalRequest, response.originalRequest)
        XCTAssertEqual(decoded.finalAnswer, response.finalAnswer)
        XCTAssertEqual(decoded.overallConfidence, response.overallConfidence)
    }
    
    // MARK: - IntentAnalysis Tests
    
    func testIntentAnalysisCreation() {
        let intent = IntentAnalysis(
            primaryIntent: "Find information",
            keyElements: ["search", "query", "results"],
            ambiguities: ["Unclear scope"],
            confidence: 0.75
        )
        
        XCTAssertEqual(intent.primaryIntent, "Find information")
        XCTAssertEqual(intent.keyElements.count, 3)
        XCTAssertEqual(intent.ambiguities?.count, 1)
        XCTAssertEqual(intent.confidence, 0.75)
    }
    
    // MARK: - Alternative Tests
    
    func testAlternativeCreation() {
        let alternative = Alternative(
            description: "Option A",
            pros: ["Fast", "Simple"],
            cons: ["Limited"],
            chosen: true,
            reasoning: "Best for this case"
        )
        
        XCTAssertEqual(alternative.description, "Option A")
        XCTAssertEqual(alternative.pros.count, 2)
        XCTAssertEqual(alternative.cons.count, 1)
        XCTAssertTrue(alternative.chosen)
    }
    
    // MARK: - ThinkingSession Tests
    
    func testThinkingSessionCreation() {
        let config = ThinkingConfiguration(strategy: .chainOfThought)
        let session = ThinkingSession(
            configuration: config,
            systemInstructions: "Test instructions",
            tools: nil,
            transcript: nil
        )
        
        XCTAssertEqual(session.configuration.strategy, .chainOfThought)
        XCTAssertEqual(session.systemInstructions, "Test instructions")
        XCTAssertNil(session.tools)
        XCTAssertNil(session.transcript)
    }
    
    func testThinkAndRespondChainOfThought() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(strategy: .chainOfThought)
        )
        
        let response = try await session.thinkAndRespond(to: "What is 2+2?")
        
        XCTAssertEqual(response.originalRequest, "What is 2+2?")
        XCTAssertFalse(response.finalAnswer.isEmpty)
        XCTAssertEqual(response.metadata.strategy, .chainOfThought)
        XCTAssertGreaterThan(response.reasoningTrace.count, 0)
        XCTAssertNotNil(response.metadata.processingTime)
    }
    
    func testThinkAndRespondReflection() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(strategy: .reflection)
        )
        
        let response = try await session.thinkAndRespond(to: "Explain photosynthesis")
        
        XCTAssertEqual(response.metadata.strategy, .reflection)
        XCTAssertGreaterThanOrEqual(response.metadata.iterations, 2)
        XCTAssertGreaterThan(response.reasoningTrace.count, 0)
    }
    
    func testThinkAndRespondDecomposition() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(strategy: .decomposition)
        )
        
        let response = try await session.thinkAndRespond(to: "How do I build a website?")
        
        XCTAssertEqual(response.metadata.strategy, .decomposition)
        XCTAssertGreaterThan(response.reasoningTrace.count, 1)
    }
    
    func testThinkAndRespondSelfConsistency() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(
                strategy: .selfConsistency,
                parallelPaths: 5
            )
        )
        
        let response = try await session.thinkAndRespond(to: "Is this statement true?")
        
        XCTAssertEqual(response.metadata.strategy, .selfConsistency)
        XCTAssertEqual(response.metadata.parallelPaths, 5)
    }
    
    func testThinkAndRespondExploration() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(strategy: .exploration)
        )
        
        let response = try await session.thinkAndRespond(to: "What's the best approach?")
        
        XCTAssertEqual(response.metadata.strategy, .exploration)
        XCTAssertNotNil(response.alternativesConsidered)
        XCTAssertGreaterThan(response.alternativesConsidered?.count ?? 0, 0)
    }
    
    func testThinkAndRespondRecursiveRefinement() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(
                strategy: .recursiveRefinement,
                maxIterations: 4
            )
        )
        
        let response = try await session.thinkAndRespond(to: "Write a summary")
        
        XCTAssertEqual(response.metadata.strategy, .recursiveRefinement)
        XCTAssertEqual(response.metadata.iterations, 4)
    }
    
    func testThinkAndRespondFull() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration.deep
        )
        
        let response = try await session.thinkAndRespond(to: "Complex question")
        
        XCTAssertEqual(response.metadata.strategy, .full)
        XCTAssertNotNil(response.intentAnalysis)
        XCTAssertGreaterThan(response.reasoningTrace.count, 3)
        XCTAssertNotNil(response.alternativesConsidered)
    }
    
    func testThinkAndRespondLight() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration.light
        )
        
        let response = try await session.thinkAndRespond(to: "Simple question")
        
        XCTAssertEqual(response.metadata.strategy, .light)
        XCTAssertEqual(response.metadata.iterations, 1)
    }
    
    func testRefinePrompt() async throws {
        let session = ThinkingSession()
        let refined = try await session.refinePrompt(original: "Tell me stuff")
        
        XCTAssertFalse(refined.isEmpty)
        XCTAssertTrue(refined.contains("Tell me stuff"))
    }
    
    func testAnalyzeIntent() async throws {
        let session = ThinkingSession()
        let intent = try await session.analyzeIntent(userPrompt: "Find restaurants nearby")
        
        XCTAssertFalse(intent.primaryIntent.isEmpty)
        XCTAssertGreaterThan(intent.keyElements.count, 0)
    }
    
    func testDecomposeAndChain() async throws {
        let session = ThinkingSession()
        let decomposition = try await session.decomposeAndChain(
            complexPrompt: "Plan a vacation with flights, hotel, and activities"
        )
        
        XCTAssertFalse(decomposition.isEmpty)
        XCTAssertTrue(decomposition.contains("Step"))
    }
    
    func testStrategyOverride() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(strategy: .light)
        )
        
        // Override with chain of thought
        let response = try await session.thinkAndRespond(
            to: "Test",
            strategy: .chainOfThought
        )
        
        XCTAssertEqual(response.metadata.strategy, .chainOfThought)
    }
    
    // MARK: - ToolDefinition Tests
    
    func testToolDefinitionCreation() {
        let param = ToolParameter(
            type: "string",
            description: "A test parameter",
            required: true
        )
        
        let tool = ToolDefinition(
            name: "testTool",
            description: "A test tool",
            parameters: ["param1": param]
        )
        
        XCTAssertEqual(tool.name, "testTool")
        XCTAssertEqual(tool.description, "A test tool")
        XCTAssertEqual(tool.parameters.count, 1)
    }
    
    // MARK: - TranscriptEntry Tests
    
    func testTranscriptEntryCreation() {
        let entry = TranscriptEntry(
            role: .user,
            content: "Hello",
            timestamp: Date()
        )
        
        XCTAssertEqual(entry.role, .user)
        XCTAssertEqual(entry.content, "Hello")
    }
    
    // MARK: - PromptTemplates Tests
    
    func testChainOfThoughtPrompt() {
        let prompt = PromptTemplates.chainOfThoughtPrompt(for: "Test request")
        XCTAssertTrue(prompt.contains("Test request"))
        XCTAssertTrue(prompt.contains("step by step"))
    }
    
    func testIntentAnalysisPrompt() {
        let prompt = PromptTemplates.intentAnalysisPrompt(for: "Find information")
        XCTAssertTrue(prompt.contains("Find information"))
        XCTAssertTrue(prompt.contains("Primary Intent"))
    }
    
    func testPromptRefinementTemplate() {
        let prompt = PromptTemplates.promptRefinementTemplate(for: "Original prompt")
        XCTAssertTrue(prompt.contains("Original prompt"))
        XCTAssertTrue(prompt.contains("Refined"))
    }
    
    func testReflectionPrompt() {
        let prompt = PromptTemplates.reflectionPrompt(for: "Draft response")
        XCTAssertTrue(prompt.contains("Draft response"))
        XCTAssertTrue(prompt.contains("critique"))
    }
    
    func testDecompositionPrompt() {
        let prompt = PromptTemplates.decompositionPrompt(for: "Complex task")
        XCTAssertTrue(prompt.contains("Complex task"))
        XCTAssertTrue(prompt.contains("steps"))
    }
    
    func testAlternativesExplorationPrompt() {
        let prompt = PromptTemplates.alternativesExplorationPrompt(for: "Decision needed")
        XCTAssertTrue(prompt.contains("Decision needed"))
        XCTAssertTrue(prompt.contains("Approach"))
    }
    
    func testFullThinkingPrompt() {
        let prompt = PromptTemplates.fullThinkingPrompt(for: "Request")
        XCTAssertTrue(prompt.contains("Request"))
        XCTAssertTrue(prompt.contains("INTENT ANALYSIS"))
        XCTAssertTrue(prompt.contains("REFLECTION"))
    }
    
    func testLightThinkingPrompt() {
        let prompt = PromptTemplates.lightThinkingPrompt(for: "Quick question")
        XCTAssertTrue(prompt.contains("Quick question"))
        XCTAssertTrue(prompt.contains("concise"))
    }
}
