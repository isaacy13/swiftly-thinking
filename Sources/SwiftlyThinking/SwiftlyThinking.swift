import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

public enum ThinkingStrategy: String, Codable, Sendable {
    case cot
    case reflection
    case decomposition
    case full
    case intentOnly
    case light
}

public enum ThinkingMode: String, Codable, Sendable {
    case light
    case deep
}

#if canImport(FoundationModels)
@Generable
public enum ConfidenceLevel: String, Codable, Sendable {
    case high
    case medium
    case low
    case unknown
}
#else
public enum ConfidenceLevel: String, Codable, Sendable {
    case high
    case medium
    case low
    case unknown
}
#endif

public enum ReasoningRedaction: String, Codable, Sendable {
    case full
    case summarized
    case redacted
}

public enum StructuredOutputFallback: String, Codable, Sendable {
    case throwError
    case fallbackToRaw
}

public struct ThinkingOptions: Codable, Sendable, Equatable {
    public var strategy: ThinkingStrategy
    public var mode: ThinkingMode
    public var maxRefinementIterations: Int
    public var selfConsistencySamples: Int
    public var maxDecompositionSteps: Int
    public var maxToolCalls: Int
    public var toolTimeout: TimeInterval?
    public var reasoningRedaction: ReasoningRedaction
    public var streamReasoning: Bool
    public var decodingFallback: StructuredOutputFallback
    public var summaryCharacterLimit: Int
    public var streamChunkSize: Int

    public init(
        strategy: ThinkingStrategy = .cot,
        mode: ThinkingMode = .light,
        maxRefinementIterations: Int = 1,
        selfConsistencySamples: Int = 1,
        maxDecompositionSteps: Int = 4,
        maxToolCalls: Int = 3,
        toolTimeout: TimeInterval? = 10,
        reasoningRedaction: ReasoningRedaction = .redacted,
        streamReasoning: Bool = false,
        decodingFallback: StructuredOutputFallback = .fallbackToRaw,
        summaryCharacterLimit: Int = 200,
        streamChunkSize: Int = 120
    ) {
        self.strategy = strategy
        self.mode = mode
        self.maxRefinementIterations = max(1, maxRefinementIterations)
        self.selfConsistencySamples = max(1, selfConsistencySamples)
        self.maxDecompositionSteps = max(1, maxDecompositionSteps)
        self.maxToolCalls = max(1, maxToolCalls)
        self.toolTimeout = toolTimeout
        self.reasoningRedaction = reasoningRedaction
        self.streamReasoning = streamReasoning
        self.decodingFallback = decodingFallback
        self.summaryCharacterLimit = max(50, summaryCharacterLimit)
        self.streamChunkSize = max(20, streamChunkSize)
    }
}

public struct ThinkingTool: Codable, Sendable, Equatable {
    public var name: String
    public var description: String
    public var parametersSchema: String?
    public var parametersType: String?

    public init(
        name: String,
        description: String,
        parametersSchema: String? = nil,
        parametersType: String? = nil
    ) {
        self.name = name
        self.description = description
        self.parametersSchema = parametersSchema
        self.parametersType = parametersType
    }
}

public enum JSONValue: Codable, Sendable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public func encodedData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

public struct ToolCall: Codable, Sendable, Equatable {
    public var tool: String
    public var arguments: [String: JSONValue]?

    public init(tool: String, arguments: [String: JSONValue]? = nil) {
        self.tool = tool
        self.arguments = arguments
    }
}

public struct ExecutableTool: Sendable {
    public let name: String
    public let description: String
    public let parametersSchema: String?
    public let parametersType: String?
    public let resultType: String?
    public let timeout: TimeInterval?
    private let handler: @Sendable (Data) async throws -> String

    public init<Parameters: Decodable & Sendable, Result: Encodable & Sendable>(
        name: String,
        description: String,
        parametersSchema: String? = nil,
        timeout: TimeInterval? = nil,
        handler: @escaping @Sendable (Parameters) async throws -> Result
    ) {
        self.name = name
        self.description = description
        self.parametersSchema = parametersSchema
        self.parametersType = String(describing: Parameters.self)
        self.resultType = String(describing: Result.self)
        self.timeout = timeout
        self.handler = { data in
            let parameters = try JSONDecoder().decode(Parameters.self, from: data)
            let result = try await handler(parameters)
            if let resultString = result as? String {
                return resultString
            }
            let encoded = try JSONEncoder().encode(result)
            return String(data: encoded, encoding: .utf8) ?? ""
        }
    }

    public func metadata() -> ThinkingTool {
        ThinkingTool(
            name: name,
            description: description,
            parametersSchema: parametersSchema,
            parametersType: parametersType
        )
    }

    public func execute(with arguments: [String: JSONValue]?, fallbackTimeout: TimeInterval?) async throws -> String {
        let data = try JSONEncoder().encode(arguments ?? [:])
        let timeoutSeconds = timeout ?? fallbackTimeout
        if let timeoutSeconds {
            let validatedTimeout = try validatedTimeout(timeoutSeconds)
            return try await withTimeout(seconds: validatedTimeout) {
                try await handler(data)
            }
        }
        return try await handler(data)
    }
}

public struct TranscriptEntry: Codable, Sendable, Equatable {
    public enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
        case tool
        case thinking
    }

    public var role: Role
    public var content: String
    public var metadata: [String: String]?

    public init(role: Role, content: String, metadata: [String: String]? = nil) {
        self.role = role
        self.content = content
        self.metadata = metadata
    }
}

#if canImport(FoundationModels)
@Generable
public struct ReasonedResponse: Codable, Sendable, Equatable {
    public var intentAnalysis: String
    public var refinedPrompt: String?
    public var reasoningTrace: [String]
    public var decisionsExplained: [String]
    public var alternatives: [String]
    public var reflectionCritique: String?
    public var reflectionRevised: String?
    public var toolRationale: String?
    public var selectionRationale: String?
    public var finalAnswer: String
    public var confidence: ConfidenceLevel

    @available(*, deprecated, message: "Use reflectionCritique and reflectionRevised for separate critique and revision values")
    public var reflection: String? {
        reflectionCritique
    }

    public init(
        intentAnalysis: String,
        refinedPrompt: String? = nil,
        reasoningTrace: [String] = [],
        decisionsExplained: [String] = [],
        alternatives: [String] = [],
        reflectionCritique: String? = nil,
        reflectionRevised: String? = nil,
        reflection: String? = nil,
        toolRationale: String? = nil,
        selectionRationale: String? = nil,
        finalAnswer: String,
        confidence: ConfidenceLevel = .unknown
    ) {
        self.intentAnalysis = intentAnalysis
        self.refinedPrompt = refinedPrompt
        self.reasoningTrace = reasoningTrace
        self.decisionsExplained = decisionsExplained
        self.alternatives = alternatives
        self.reflectionCritique = resolvedReflectionCritique(reflectionCritique, reflection)
        self.reflectionRevised = reflectionRevised
        self.toolRationale = toolRationale
        self.selectionRationale = selectionRationale
        self.finalAnswer = finalAnswer
        self.confidence = confidence
    }

    private enum CodingKeys: String, CodingKey {
        case intentAnalysis = "intent_analysis"
        case refinedPrompt = "refined_prompt"
        case reasoningTrace = "reasoning_trace"
        case decisionsExplained = "decisions_explained"
        case alternatives
        case reflection
        case reflectionCritique = "reflection_critique"
        case reflectionRevised = "reflection_revised"
        case toolRationale = "tool_rationale"
        case selectionRationale = "selection_rationale"
        case finalAnswer = "final_answer"
        case confidence
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intentAnalysis = try container.decodeIfPresent(String.self, forKey: .intentAnalysis) ?? ""
        refinedPrompt = try container.decodeIfPresent(String.self, forKey: .refinedPrompt)
        reasoningTrace = try container.decodeIfPresent([String].self, forKey: .reasoningTrace) ?? []
        decisionsExplained = try container.decodeIfPresent([String].self, forKey: .decisionsExplained) ?? []
        alternatives = try container.decodeIfPresent([String].self, forKey: .alternatives) ?? []
        reflectionCritique = try container.decodeIfPresent(String.self, forKey: .reflectionCritique)
            ?? container.decodeIfPresent(String.self, forKey: .reflection)
        reflectionRevised = try container.decodeIfPresent(String.self, forKey: .reflectionRevised)
        toolRationale = try container.decodeIfPresent(String.self, forKey: .toolRationale)
        selectionRationale = try container.decodeIfPresent(String.self, forKey: .selectionRationale)
        finalAnswer = try container.decodeIfPresent(String.self, forKey: .finalAnswer) ?? ""
        confidence = try container.decodeIfPresent(ConfidenceLevel.self, forKey: .confidence) ?? .unknown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(intentAnalysis, forKey: .intentAnalysis)
        try container.encode(refinedPrompt, forKey: .refinedPrompt)
        try container.encode(reasoningTrace, forKey: .reasoningTrace)
        try container.encode(decisionsExplained, forKey: .decisionsExplained)
        try container.encode(alternatives, forKey: .alternatives)
        try container.encode(reflectionCritique, forKey: .reflectionCritique)
        try container.encode(reflectionRevised, forKey: .reflectionRevised)
        try container.encode(toolRationale, forKey: .toolRationale)
        try container.encode(selectionRationale, forKey: .selectionRationale)
        try container.encode(finalAnswer, forKey: .finalAnswer)
        try container.encode(confidence, forKey: .confidence)
    }
}
#else
public struct ReasonedResponse: Codable, Sendable, Equatable {
    public var intentAnalysis: String
    public var refinedPrompt: String?
    public var reasoningTrace: [String]
    public var decisionsExplained: [String]
    public var alternatives: [String]
    public var reflectionCritique: String?
    public var reflectionRevised: String?
    public var toolRationale: String?
    public var selectionRationale: String?
    public var finalAnswer: String
    public var confidence: ConfidenceLevel

    @available(*, deprecated, message: "Use reflectionCritique and reflectionRevised for separate critique and revision values")
    public var reflection: String? {
        reflectionCritique
    }

    public init(
        intentAnalysis: String,
        refinedPrompt: String? = nil,
        reasoningTrace: [String] = [],
        decisionsExplained: [String] = [],
        alternatives: [String] = [],
        reflectionCritique: String? = nil,
        reflectionRevised: String? = nil,
        reflection: String? = nil,
        toolRationale: String? = nil,
        selectionRationale: String? = nil,
        finalAnswer: String,
        confidence: ConfidenceLevel = .unknown
    ) {
        self.intentAnalysis = intentAnalysis
        self.refinedPrompt = refinedPrompt
        self.reasoningTrace = reasoningTrace
        self.decisionsExplained = decisionsExplained
        self.alternatives = alternatives
        self.reflectionCritique = resolvedReflectionCritique(reflectionCritique, reflection)
        self.reflectionRevised = reflectionRevised
        self.toolRationale = toolRationale
        self.selectionRationale = selectionRationale
        self.finalAnswer = finalAnswer
        self.confidence = confidence
    }

    private enum CodingKeys: String, CodingKey {
        case intentAnalysis = "intent_analysis"
        case refinedPrompt = "refined_prompt"
        case reasoningTrace = "reasoning_trace"
        case decisionsExplained = "decisions_explained"
        case alternatives
        case reflection
        case reflectionCritique = "reflection_critique"
        case reflectionRevised = "reflection_revised"
        case toolRationale = "tool_rationale"
        case selectionRationale = "selection_rationale"
        case finalAnswer = "final_answer"
        case confidence
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intentAnalysis = try container.decodeIfPresent(String.self, forKey: .intentAnalysis) ?? ""
        refinedPrompt = try container.decodeIfPresent(String.self, forKey: .refinedPrompt)
        reasoningTrace = try container.decodeIfPresent([String].self, forKey: .reasoningTrace) ?? []
        decisionsExplained = try container.decodeIfPresent([String].self, forKey: .decisionsExplained) ?? []
        alternatives = try container.decodeIfPresent([String].self, forKey: .alternatives) ?? []
        reflectionCritique = try container.decodeIfPresent(String.self, forKey: .reflectionCritique)
            ?? container.decodeIfPresent(String.self, forKey: .reflection)
        reflectionRevised = try container.decodeIfPresent(String.self, forKey: .reflectionRevised)
        toolRationale = try container.decodeIfPresent(String.self, forKey: .toolRationale)
        selectionRationale = try container.decodeIfPresent(String.self, forKey: .selectionRationale)
        finalAnswer = try container.decodeIfPresent(String.self, forKey: .finalAnswer) ?? ""
        confidence = try container.decodeIfPresent(ConfidenceLevel.self, forKey: .confidence) ?? .unknown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(intentAnalysis, forKey: .intentAnalysis)
        try container.encode(refinedPrompt, forKey: .refinedPrompt)
        try container.encode(reasoningTrace, forKey: .reasoningTrace)
        try container.encode(decisionsExplained, forKey: .decisionsExplained)
        try container.encode(alternatives, forKey: .alternatives)
        try container.encode(reflectionCritique, forKey: .reflectionCritique)
        try container.encode(reflectionRevised, forKey: .reflectionRevised)
        try container.encode(toolRationale, forKey: .toolRationale)
        try container.encode(selectionRationale, forKey: .selectionRationale)
        try container.encode(finalAnswer, forKey: .finalAnswer)
        try container.encode(confidence, forKey: .confidence)
    }
}
#endif

#if canImport(FoundationModels)
@Generable
public struct ReflectionResult: Codable, Sendable, Equatable {
    public var critique: String
    public var revisedAnswer: String

    public init(critique: String, revisedAnswer: String) {
        self.critique = critique
        self.revisedAnswer = revisedAnswer
    }

    private enum CodingKeys: String, CodingKey {
        case critique
        case revisedAnswer = "revised_answer"
    }
}
#else
public struct ReflectionResult: Codable, Sendable, Equatable {
    public var critique: String
    public var revisedAnswer: String

    public init(critique: String, revisedAnswer: String) {
        self.critique = critique
        self.revisedAnswer = revisedAnswer
    }

    private enum CodingKeys: String, CodingKey {
        case critique
        case revisedAnswer = "revised_answer"
    }
}
#endif

private func resolvedReflectionCritique(_ reflectionCritique: String?, _ reflection: String?) -> String? {
    reflectionCritique ?? reflection
}

public struct PromptTemplates: Sendable, Equatable {
    public var intentAnalysis: String
    public var refinement: String
    public var chainOfThought: String
    public var decomposition: String
    public var solveStep: String
    public var recombine: String
    public var reflection: String
    public var alternatives: String
    public var toolRationale: String
    public var selfConsistency: String

    public init(
        intentAnalysis: String,
        refinement: String,
        chainOfThought: String,
        decomposition: String,
        solveStep: String,
        recombine: String,
        reflection: String,
        alternatives: String,
        toolRationale: String,
        selfConsistency: String
    ) {
        self.intentAnalysis = intentAnalysis
        self.refinement = refinement
        self.chainOfThought = chainOfThought
        self.decomposition = decomposition
        self.solveStep = solveStep
        self.recombine = recombine
        self.reflection = reflection
        self.alternatives = alternatives
        self.toolRationale = toolRationale
        self.selfConsistency = selfConsistency
    }

    public static let `default` = PromptTemplates(
        intentAnalysis: """
        Interpret the user's request. Provide: intent summary, key elements, and ambiguities.\nPrompt: {prompt}
        """,
        refinement: """
        Refine this user prompt for clarity and specificity. Return only the refined prompt.\nPrompt: {prompt}
        """,
        chainOfThought: """
        Think step by step. Intent: {intent}. Tools: {tools}.\nReturn a structured response with intent analysis, reasoning trace, decisions, alternatives, reflection critique, revised answer, tool rationale, selection rationale, final answer, and confidence.\nPrompt: {prompt}
        """,
        decomposition: """
        Decompose the request into {max_steps} steps. Provide a numbered list with short rationales.\nPrompt: {prompt}
        """,
        solveStep: """
        Solve step {step_index}: {step}. Explain why this step matters and output the result.
        """,
        recombine: """
        Combine the step results into a cohesive answer with rationale.\nSteps: {steps}\nResults: {results}
        """,
        reflection: """
        Review the draft response for accuracy, gaps, or weak reasoning. Provide a critique and a revised answer.\nDraft: {draft}
        """,
        alternatives: """
        Explore alternative perspectives, pros/cons, and tradeoffs for: {prompt}\nProvide a short comparison.
        """,
        toolRationale: """
        If tools are available, explain which tool you would call and why. Tools: {tools}\nPrompt: {prompt}
        """,
        selfConsistency: """
        Generate an independent reasoning path. Return a structured response with reasoning, decisions, and a final answer.\nPrompt: {prompt}
        """
    )
}

public enum ThinkingSessionError: Error {
    case emptyResponse
    case unableToParseStructuredOutput
    case toolCallLimitReached
    case toolNotFound(String)
    case toolExecutionFailed(String)
    case toolTimeout(String)
}

public protocol ThinkingSessionClient: Sendable {
    func generateResponse(for prompt: String, configuration: ThinkingSession.Configuration) async throws -> String
}

public protocol StreamingThinkingSessionClient: ThinkingSessionClient {
    func streamResponse(
        for prompt: String,
        configuration: ThinkingSession.Configuration
    ) -> AsyncThrowingStream<String, Error>
}

public struct ThinkingSession: Sendable {
    public struct Configuration: Codable, Sendable, Equatable {
        public var instructions: String?
        public var tools: [ThinkingTool]
        public var transcript: [TranscriptEntry]
        public var generationSchema: String?

        public init(
            instructions: String? = nil,
            tools: [ThinkingTool] = [],
            transcript: [TranscriptEntry] = [],
            generationSchema: String? = nil
        ) {
            self.instructions = instructions
            self.tools = tools
            self.transcript = transcript
            self.generationSchema = generationSchema
        }
    }

    private struct StrategyProfile {
        var includesRefinement: Bool
        var includesIntent: Bool
        var includesDecomposition: Bool
        var includesReflection: Bool
        var includesAlternatives: Bool
        var includesSelfConsistency: Bool
        var includesToolRationale: Bool
    }

    private struct StreamContext {
        var onTranscriptUpdate: (@Sendable (TranscriptEntry) async -> Void)?
        var onReasoningUpdate: (@Sendable (TranscriptEntry) async -> Void)?
    }

    public var configuration: Configuration
    public var options: ThinkingOptions
    public var prompts: PromptTemplates
    public private(set) var transcript: [TranscriptEntry]
    public var executableTools: [ExecutableTool]

    private let client: any ThinkingSessionClient

    public init(
        configuration: Configuration = Configuration(),
        options: ThinkingOptions = ThinkingOptions(),
        prompts: PromptTemplates = .default,
        executableTools: [ExecutableTool] = [],
        client: some ThinkingSessionClient
    ) {
        self.configuration = configuration
        self.options = options
        self.prompts = prompts
        self.client = client
        self.transcript = configuration.transcript
        self.executableTools = executableTools
    }

    public init(
        configuration: Configuration = Configuration(),
        options: ThinkingOptions = ThinkingOptions(),
        prompts: PromptTemplates = .default,
        executableTools: [ExecutableTool] = [],
        respond: @escaping @Sendable (String, Configuration) async throws -> String
    ) {
        self.init(
            configuration: configuration,
            options: options,
            prompts: prompts,
            executableTools: executableTools,
            client: ClosureClient(respond: respond)
        )
    }

    public mutating func thinkAndRespond(
        to userPrompt: String,
        strategy: ThinkingStrategy? = nil
    ) async throws -> ReasonedResponse {
        try await runThinkingPipeline(to: userPrompt, strategy: strategy, streamContext: nil)
    }

    public mutating func thinkAndRespondStream(
        to userPrompt: String,
        strategy: ThinkingStrategy? = nil,
        onTranscriptUpdate: @escaping @Sendable (TranscriptEntry) async -> Void,
        onReasoningUpdate: (@Sendable (TranscriptEntry) async -> Void)? = nil
    ) async throws -> ReasonedResponse {
        let context = StreamContext(
            onTranscriptUpdate: onTranscriptUpdate,
            onReasoningUpdate: onReasoningUpdate
        )
        return try await runThinkingPipeline(to: userPrompt, strategy: strategy, streamContext: context)
    }

    public mutating func respond<T: Decodable>(
        to prompt: String,
        outputType: T.Type
    ) async throws -> T {
        let note = "Generating structured response (\(outputType))"
        let response: T = try await requestStructuredResponse(
            prompt,
            note: note,
            streamContext: nil
        )
        return response
    }

    private mutating func runThinkingPipeline(
        to userPrompt: String,
        strategy: ThinkingStrategy? = nil,
        streamContext: StreamContext?
    ) async throws -> ReasonedResponse {
        let strategy = strategy ?? options.strategy
        let profile = profileFor(strategy: strategy)
        let basePrompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        appendEntry(role: .user, content: basePrompt)
        await emitTranscriptUpdate(TranscriptEntry(role: .user, content: basePrompt), streamContext: streamContext)

        var refinedPrompt = basePrompt
        if profile.includesRefinement {
            refinedPrompt = try await refinePrompt(original: basePrompt, streamContext: streamContext)
        }

        var intentAnalysis = ""
        if profile.includesIntent {
            intentAnalysis = try await analyzeIntent(for: refinedPrompt, streamContext: streamContext)
        }

        var reasoningTrace: [String] = []
        var decisions: [String] = []
        var alternatives: [String] = []
        var toolRationale: String? = nil

        if profile.includesAlternatives {
            let alternative = try await exploreAlternatives(for: refinedPrompt, streamContext: streamContext)
            alternatives.append(alternative)
            reasoningTrace.append(alternative)
        }

        if profile.includesToolRationale {
            toolRationale = try await explainToolRationale(for: refinedPrompt, streamContext: streamContext)
            if let toolRationale {
                reasoningTrace.append(toolRationale)
            }
        }

        if profile.includesDecomposition {
            let decomposition = try await decomposeAndChain(complexPrompt: refinedPrompt, streamContext: streamContext)
            reasoningTrace.append(decomposition)
            decisions.append("Decomposed the request into sequenced steps for clarity.")
        }

        let draftResponse = try await generateDraft(prompt: refinedPrompt, intent: intentAnalysis, streamContext: streamContext)
        var currentAnswer = draftResponse.finalAnswer
        reasoningTrace.append(contentsOf: draftResponse.reasoningTrace.isEmpty ? [currentAnswer] : draftResponse.reasoningTrace)

        var reflectionCritique: String? = draftResponse.reflectionCritique
        var reflectionRevised: String? = draftResponse.reflectionRevised
        if profile.includesReflection {
            for _ in 0..<options.maxRefinementIterations {
                let reflection = try await reflectOnDraft(currentAnswer, streamContext: streamContext)
                reflectionCritique = reflection.critique
                reflectionRevised = reflection.revisedAnswer
                currentAnswer = reflection.revisedAnswer
            }
        }

        var selectionRationale: String? = nil
        if profile.includesSelfConsistency && options.selfConsistencySamples > 1 {
            let selection = try await chooseSelfConsistentAnswer(
                prompt: refinedPrompt,
                intent: intentAnalysis,
                streamContext: streamContext
            )
            currentAnswer = selection.answer
            alternatives.append(contentsOf: selection.candidates)
            selectionRationale = selection.rationale
        }

        let redactedReasoningTrace = reasoningTrace.map { redactReasoning($0) }
        let finalResponse = ReasonedResponse(
            intentAnalysis: draftResponse.intentAnalysis.isEmpty ? intentAnalysis : draftResponse.intentAnalysis,
            refinedPrompt: draftResponse.refinedPrompt ?? refinedPrompt,
            reasoningTrace: redactedReasoningTrace,
            decisionsExplained: mergeUnique(draftResponse.decisionsExplained, decisions),
            alternatives: mergeUnique(draftResponse.alternatives, alternatives),
            reflectionCritique: reflectionCritique ?? draftResponse.reflectionCritique,
            reflectionRevised: reflectionRevised ?? draftResponse.reflectionRevised ?? currentAnswer,
            toolRationale: draftResponse.toolRationale ?? toolRationale,
            selectionRationale: draftResponse.selectionRationale ?? selectionRationale,
            finalAnswer: currentAnswer,
            confidence: draftResponse.confidence
        )

        let assistantEntry = TranscriptEntry(role: .assistant, content: finalResponse.finalAnswer)
        if let streamContext {
            await streamTranscriptContent(assistantEntry, streamContext: streamContext)
        } else {
            appendEntry(role: .assistant, content: finalResponse.finalAnswer)
        }
        return finalResponse
    }

    public mutating func refinePrompt(original: String) async throws -> String {
        try await refinePrompt(original: original, streamContext: nil)
    }

    public mutating func analyzeIntent(for promptText: String) async throws -> String {
        try await analyzeIntent(for: promptText, streamContext: nil)
    }

    public mutating func decomposeAndChain(complexPrompt: String) async throws -> String {
        try await decomposeAndChain(complexPrompt: complexPrompt, streamContext: nil)
    }

    public mutating func reflectOnDraft(_ draft: String) async throws -> ReflectionResult {
        try await reflectOnDraft(draft, streamContext: nil)
    }

    public mutating func exploreAlternatives(for promptText: String) async throws -> String {
        try await exploreAlternatives(for: promptText, streamContext: nil)
    }

    public mutating func explainToolRationale(for promptText: String) async throws -> String? {
        try await explainToolRationale(for: promptText, streamContext: nil)
    }

    private mutating func refinePrompt(original: String, streamContext: StreamContext?) async throws -> String {
        let prompt = render(prompts.refinement, values: ["prompt": original])
        let response = try await requestResponse(prompt, note: "Refining prompt", streamContext: streamContext)
        return response
    }

    private mutating func analyzeIntent(for promptText: String, streamContext: StreamContext?) async throws -> String {
        let prompt = render(prompts.intentAnalysis, values: ["prompt": promptText])
        return try await requestResponse(prompt, note: "Analyzing intent", streamContext: streamContext)
    }

    private mutating func decomposeAndChain(complexPrompt: String, streamContext: StreamContext?) async throws -> String {
        let prompt = render(prompts.decomposition, values: [
            "prompt": complexPrompt,
            "max_steps": "\(options.maxDecompositionSteps)"
        ])
        let decomposition = try await requestResponse(prompt, note: "Decomposing request", streamContext: streamContext)
        let steps = extractSteps(from: decomposition)

        var stepResults: [String] = []
        for (index, step) in steps.enumerated() {
            let stepPrompt = render(prompts.solveStep, values: [
                "step_index": "\(index + 1)",
                "step": step
            ])
            let result = try await requestResponse(stepPrompt, note: "Solving step \(index + 1)", streamContext: streamContext)
            stepResults.append(result)
        }

        let recombinePrompt = render(prompts.recombine, values: [
            "steps": steps.joined(separator: "\n"),
            "results": stepResults.joined(separator: "\n")
        ])
        let recombined = try await requestResponse(recombinePrompt, note: "Recombining steps", streamContext: streamContext)
        return """
        Decomposition:\n\(decomposition)\n\nStep Results:\n\(stepResults.joined(separator: "\n"))\n\nRecombined Answer:\n\(recombined)
        """
    }

    private mutating func reflectOnDraft(_ draft: String, streamContext: StreamContext?) async throws -> ReflectionResult {
        let prompt = render(prompts.reflection, values: ["draft": draft])
        return try await requestStructuredResponse(prompt, note: "Reflecting on draft", streamContext: streamContext, fallback: {
            ReflectionResult(
                critique: "Failed to parse reflection response. Using raw response as revised answer.",
                revisedAnswer: $0
            )
        })
    }

    private mutating func exploreAlternatives(for promptText: String, streamContext: StreamContext?) async throws -> String {
        let prompt = render(prompts.alternatives, values: ["prompt": promptText])
        return try await requestResponse(prompt, note: "Exploring alternatives", streamContext: streamContext)
    }

    private mutating func explainToolRationale(for promptText: String, streamContext: StreamContext?) async throws -> String? {
        guard !allTools().isEmpty else { return nil }
        let prompt = render(prompts.toolRationale, values: [
            "prompt": promptText,
            "tools": toolSummary()
        ])
        return try await requestResponse(prompt, note: "Explaining tool rationale", streamContext: streamContext)
    }

    private mutating func generateDraft(
        prompt: String,
        intent: String,
        streamContext: StreamContext?
    ) async throws -> ReasonedResponse {
        let promptText = render(prompts.chainOfThought, values: [
            "prompt": prompt,
            "intent": intent.isEmpty ? "No explicit intent analysis" : intent,
            "tools": toolSummary()
        ])
        return try await requestStructuredResponse(
            promptText,
            note: "Generating draft",
            streamContext: streamContext,
            fallback: { raw in
                ReasonedResponse(
                    intentAnalysis: intent,
                    refinedPrompt: prompt,
                    reasoningTrace: [raw],
                    decisionsExplained: [],
                    alternatives: [],
                    reflectionCritique: nil,
                    reflectionRevised: nil,
                    toolRationale: nil,
                    selectionRationale: nil,
                    finalAnswer: raw,
                    confidence: .unknown
                )
            }
        )
    }

    private mutating func chooseSelfConsistentAnswer(
        prompt: String,
        intent: String,
        streamContext: StreamContext?
    ) async throws -> (answer: String, candidates: [String], rationale: String) {
        var candidates: [String] = []
        for index in 0..<options.selfConsistencySamples {
            let promptText = render(prompts.selfConsistency, values: [
                "prompt": "(Path \(index + 1)) \(prompt)"
            ])
            let response = try await requestStructuredResponse(
                promptText,
                note: "Self-consistency path \(index + 1)",
                streamContext: streamContext,
                fallback: { raw in
                    ReasonedResponse(
                        intentAnalysis: intent,
                        refinedPrompt: nil,
                        reasoningTrace: [raw],
                        decisionsExplained: [],
                        alternatives: [],
                        reflectionCritique: nil,
                        reflectionRevised: nil,
                        toolRationale: nil,
                        selectionRationale: nil,
                        finalAnswer: raw,
                        confidence: .unknown
                    )
                }
            )
            candidates.append(response.finalAnswer)
        }

        let counts = Dictionary(grouping: candidates, by: { $0 }).mapValues { $0.count }
        let sorted = counts.sorted { $0.value > $1.value }
        let winner = sorted.first?.key ?? (candidates.first ?? "")
        let rationale = "Selected the most consistent answer: \"\(winner)\" appearing in \(sorted.first?.value ?? 0) of \(candidates.count) paths."
        return (winner, candidates, rationale)
    }

    private func profileFor(strategy: ThinkingStrategy) -> StrategyProfile {
        switch strategy {
        case .intentOnly:
            return StrategyProfile(
                includesRefinement: false,
                includesIntent: true,
                includesDecomposition: false,
                includesReflection: false,
                includesAlternatives: false,
                includesSelfConsistency: false,
                includesToolRationale: false
            )
        case .light:
            return StrategyProfile(
                includesRefinement: false,
                includesIntent: true,
                includesDecomposition: false,
                includesReflection: false,
                includesAlternatives: false,
                includesSelfConsistency: false,
                includesToolRationale: true
            )
        case .cot:
            return StrategyProfile(
                includesRefinement: false,
                includesIntent: true,
                includesDecomposition: false,
                includesReflection: false,
                includesAlternatives: false,
                includesSelfConsistency: false,
                includesToolRationale: true
            )
        case .reflection:
            return StrategyProfile(
                includesRefinement: options.mode == .deep,
                includesIntent: true,
                includesDecomposition: false,
                includesReflection: true,
                includesAlternatives: options.mode == .deep,
                includesSelfConsistency: false,
                includesToolRationale: true
            )
        case .decomposition:
            return StrategyProfile(
                includesRefinement: options.mode == .deep,
                includesIntent: true,
                includesDecomposition: true,
                includesReflection: false,
                includesAlternatives: options.mode == .deep,
                includesSelfConsistency: false,
                includesToolRationale: true
            )
        case .full:
            return StrategyProfile(
                includesRefinement: true,
                includesIntent: true,
                includesDecomposition: true,
                includesReflection: true,
                includesAlternatives: true,
                includesSelfConsistency: true,
                includesToolRationale: true
            )
        }
    }

    private enum StreamTarget {
        case transcript
        case reasoning
    }

    private mutating func requestResponse(
        _ prompt: String,
        note: String,
        streamContext: StreamContext?
    ) async throws -> String {
        let wrappedPrompt = wrapPrompt(prompt)
        appendEntry(role: .thinking, content: note, metadata: ["prompt": wrappedPrompt])
        let response = try await fetchResponse(
            for: wrappedPrompt,
            role: .thinking,
            streamTarget: .reasoning,
            streamContext: streamContext
        )
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ThinkingSessionError.emptyResponse }
        return try await resolveToolCalls(from: trimmed, streamContext: streamContext)
    }

    private mutating func requestStructuredResponse<T: Decodable>(
        _ prompt: String,
        note: String,
        streamContext: StreamContext?,
        fallback: ((String) -> T)? = nil
    ) async throws -> T {
        try await requestStructuredResponseDecoding(
            prompt,
            note: note,
            streamContext: streamContext,
            fallback: fallback
        )
    }

    #if canImport(FoundationModels)
    private mutating func requestStructuredResponse<T: Generable>(
        _ prompt: String,
        note: String,
        streamContext: StreamContext?,
        fallback: ((String) -> T)? = nil
    ) async throws -> T {
        if let foundationClient = client as? FoundationModelsClient {
            let wrappedPrompt = wrapPrompt(prompt)
            appendEntry(role: .thinking, content: note, metadata: ["prompt": wrappedPrompt])
            let response = try await foundationClient.generateStructuredResponse(
                for: wrappedPrompt,
                configuration: currentConfiguration(),
                outputType: T.self
            )
            if let data = try? JSONEncoder().encode(response),
               let encoded = String(data: data, encoding: .utf8) {
                appendEntry(role: .thinking, content: encoded)
                if let streamContext {
                    await emitReasoningUpdate(
                        TranscriptEntry(role: .thinking, content: redactReasoning(encoded)),
                        streamContext: streamContext
                    )
                }
            }
            return response
        }
        return try await requestStructuredResponseDecoding(
            prompt,
            note: note,
            streamContext: streamContext,
            fallback: fallback
        )
    }
    #endif

    private mutating func requestStructuredResponseDecoding<T: Decodable>(
        _ prompt: String,
        note: String,
        streamContext: StreamContext?,
        fallback: ((String) -> T)? = nil
    ) async throws -> T {
        let raw = try await requestResponse(prompt, note: note, streamContext: streamContext)
        return try decodeStructuredResponse(raw, fallback: fallback)
    }

    private func decodeStructuredResponse<T: Decodable>(
        _ raw: String,
        fallback: ((String) -> T)?
    ) throws -> T {
        if let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            return decoded
        }
        if options.decodingFallback == .fallbackToRaw, let fallback {
            return fallback(raw)
        }
        throw ThinkingSessionError.unableToParseStructuredOutput
    }

    private mutating func fetchResponse(
        for prompt: String,
        role: TranscriptEntry.Role,
        streamTarget: StreamTarget,
        streamContext: StreamContext?
    ) async throws -> String {
        if let streamContext {
            if let streamingClient = client as? StreamingThinkingSessionClient {
                return try await streamResponse(
                    for: prompt,
                    role: role,
                    streamTarget: streamTarget,
                    streamContext: streamContext,
                    stream: streamingClient.streamResponse(for: prompt, configuration: currentConfiguration())
                )
            }

            let response = try await client.generateResponse(for: prompt, configuration: currentConfiguration())
            let stream = AsyncThrowingStream<String, Error> { continuation in
                for chunk in chunkText(response) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
            return try await streamResponse(
                for: prompt,
                role: role,
                streamTarget: streamTarget,
                streamContext: streamContext,
                stream: stream
            )
        }

        let response = try await client.generateResponse(for: prompt, configuration: currentConfiguration())
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ThinkingSessionError.emptyResponse }
        appendEntry(role: role, content: trimmed)
        return trimmed
    }

    private mutating func streamResponse(
        for prompt: String,
        role: TranscriptEntry.Role,
        streamTarget: StreamTarget,
        streamContext: StreamContext,
        stream: AsyncThrowingStream<String, Error>
    ) async throws -> String {
        var combined = ""
        var entryIndex: Int?
        for try await chunk in stream {
            combined += chunk
            let updatedEntry = TranscriptEntry(role: role, content: combined)
            if let entryIndex {
                transcript[entryIndex] = updatedEntry
            } else {
                transcript.append(updatedEntry)
                entryIndex = transcript.count - 1
            }
            await emitStreamUpdate(updatedEntry, streamTarget: streamTarget, streamContext: streamContext)
        }
        let trimmed = combined.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ThinkingSessionError.emptyResponse }
        return trimmed
    }

    private func emitStreamUpdate(
        _ entry: TranscriptEntry,
        streamTarget: StreamTarget,
        streamContext: StreamContext
    ) async {
        switch streamTarget {
        case .transcript:
            await emitTranscriptUpdate(entry, streamContext: streamContext)
        case .reasoning:
            await emitReasoningUpdate(
                TranscriptEntry(role: entry.role, content: redactReasoning(entry.content)),
                streamContext: streamContext
            )
        }
    }

    private mutating func resolveToolCalls(
        from response: String,
        streamContext: StreamContext?
    ) async throws -> String {
        guard !executableTools.isEmpty else { return response }
        let toolLookup = Dictionary(uniqueKeysWithValues: executableTools.map { ($0.name, $0) })
        var current = response
        var remainingCalls = options.maxToolCalls

        while let toolCall = parseToolCall(from: current) {
            guard remainingCalls > 0 else { throw ThinkingSessionError.toolCallLimitReached }
            remainingCalls -= 1
            guard let tool = toolLookup[toolCall.tool] else {
                appendEntry(role: .tool, content: "Tool not found: \(toolCall.tool)", metadata: ["tool": toolCall.tool])
                throw ThinkingSessionError.toolNotFound(toolCall.tool)
            }

            do {
                let result = try await tool.execute(with: toolCall.arguments, fallbackTimeout: options.toolTimeout)
                let toolEntry = TranscriptEntry(role: .tool, content: result, metadata: ["tool": tool.name])
                appendEntry(role: .tool, content: result, metadata: ["tool": tool.name])
                await emitTranscriptUpdate(toolEntry, streamContext: streamContext)
                let followUpPrompt = "Tool result from \(tool.name): \(result)\nContinue."
                current = try await fetchResponse(
                    for: wrapPrompt(followUpPrompt),
                    role: .thinking,
                    streamTarget: .reasoning,
                    streamContext: streamContext
                )
            } catch is TimeoutError {
                appendEntry(role: .tool, content: "Tool execution timed out.", metadata: ["tool": tool.name])
                throw ThinkingSessionError.toolTimeout(tool.name)
            } catch {
                appendEntry(role: .tool, content: "Tool execution failed: \(error)", metadata: ["tool": tool.name])
                throw ThinkingSessionError.toolExecutionFailed(tool.name)
            }
        }
        return current
    }

    private func wrapPrompt(_ prompt: String) -> String {
        var header: [String] = []
        if let instructions = configuration.instructions, !instructions.isEmpty {
            header.append("System instructions: \(instructions)")
        }
        if !allTools().isEmpty {
            header.append("Available tools:\n\(toolSummary())")
            header.append("If a tool is needed, respond only with: {\"tool\":\"<name>\",\"arguments\":{...}}")
        }
        return (header + [prompt]).joined(separator: "\n\n")
    }

    private func toolSummary() -> String {
        let tools = allTools()
        guard !tools.isEmpty else { return "None" }
        return tools.map { tool in
            var line = "- \(tool.name): \(tool.description)"
            if let schema = tool.parametersSchema {
                line += " (schema: \(schema))"
            }
            if let parametersType = tool.parametersType {
                line += " (type: \(parametersType))"
            }
            return line
        }.joined(separator: "\n")
    }

    private func allTools() -> [ThinkingTool] {
        let executableMetadata = executableTools.map { $0.metadata() }
        return configuration.tools + executableMetadata
    }

    private func currentConfiguration() -> Configuration {
        var updated = configuration
        updated.transcript = transcript
        return updated
    }

    private mutating func appendEntry(role: TranscriptEntry.Role, content: String, metadata: [String: String]? = nil) {
        transcript.append(TranscriptEntry(role: role, content: content, metadata: metadata))
    }

    private func emitTranscriptUpdate(_ entry: TranscriptEntry, streamContext: StreamContext?) async {
        guard let handler = streamContext?.onTranscriptUpdate else { return }
        await handler(entry)
    }

    private func emitReasoningUpdate(_ entry: TranscriptEntry, streamContext: StreamContext?) async {
        guard options.streamReasoning, let handler = streamContext?.onReasoningUpdate else { return }
        await handler(entry)
    }

    private mutating func streamTranscriptContent(
        _ entry: TranscriptEntry,
        streamContext: StreamContext
    ) async {
        let chunks = chunkText(entry.content)
        var combined = ""
        var entryIndex: Int?
        for chunk in chunks {
            combined += chunk
            let updatedEntry = TranscriptEntry(role: entry.role, content: combined, metadata: entry.metadata)
            if let entryIndex {
                transcript[entryIndex] = updatedEntry
            } else {
                transcript.append(updatedEntry)
                entryIndex = transcript.count - 1
            }
            await emitTranscriptUpdate(updatedEntry, streamContext: streamContext)
        }
    }

    private func parseToolCall(from response: String) -> ToolCall? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let call = try? JSONDecoder().decode(ToolCall.self, from: data) {
            return call
        }
        guard let json = extractJSONObject(from: trimmed),
              let data = json.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(ToolCall.self, from: data)
    }

    private func extractJSONObject(from text: String) -> String? {
        var depth = 0
        var startIndex: String.Index?
        for index in text.indices {
            let character = text[index]
            if character == "{" {
                if depth == 0 {
                    startIndex = index
                }
                depth += 1
            } else if character == "}" {
                guard depth > 0 else { continue }
                depth -= 1
                if depth == 0, let startIndex {
                    return String(text[startIndex...index])
                }
            }
        }
        return nil
    }

    private func redactReasoning(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        switch options.reasoningRedaction {
        case .full:
            return trimmed
        case .summarized:
            return summarizeReasoning(trimmed)
        case .redacted:
            return "Reasoning redacted."
        }
    }

    private func summarizeReasoning(_ text: String) -> String {
        let maxLength = options.summaryCharacterLimit
        if text.count <= maxLength {
            return text
        }
        let snippet = String(text.prefix(maxLength))
        return "Summary: \(snippet)..."
    }

    private func chunkText(_ text: String) -> [String] {
        let size = options.streamChunkSize
        guard size > 0 else { return [text] }
        var chunks: [String] = []
        var currentIndex = text.startIndex
        while currentIndex < text.endIndex {
            let nextIndex = text.index(currentIndex, offsetBy: size, limitedBy: text.endIndex) ?? text.endIndex
            chunks.append(String(text[currentIndex..<nextIndex]))
            currentIndex = nextIndex
        }
        return chunks.isEmpty ? [""] : chunks
    }

    private func render(_ template: String, values: [String: String]) -> String {
        values.reduce(template) { partial, pair in
            partial.replacingOccurrences(of: "{\(pair.key)}", with: pair.value)
        }.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractSteps(from text: String) -> [String] {
        let lines = text.split(whereSeparator: \.isNewline)
        let steps = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return trimmed.replacingOccurrences(of: "^\\d+\\.?\\s*", with: "", options: .regularExpression)
        }
        return steps.isEmpty ? [text] : steps
    }

    private func mergeUnique(_ primary: [String], _ additional: [String]) -> [String] {
        var seen = Set<String>()
        var merged: [String] = []
        for entry in primary + additional {
            guard !entry.isEmpty, !seen.contains(entry) else { continue }
            seen.insert(entry)
            merged.append(entry)
        }
        return merged
    }
}

private let maximumAllowedTimeout: TimeInterval = 3600

private struct TimeoutError: Error {
    let seconds: TimeInterval
    let reason: String
}

private func validatedTimeout(_ seconds: TimeInterval) throws -> TimeInterval {
    guard seconds > 0 else {
        throw TimeoutError(seconds: seconds, reason: "Timeout must be greater than 0")
    }
    return seconds
}

private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    let validatedSeconds = try validatedTimeout(seconds)
    let safeSeconds = min(validatedSeconds, maximumAllowedTimeout)
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            let nanoseconds = UInt64(safeSeconds * 1_000_000_000)
            try await Task.sleep(nanoseconds: nanoseconds)
            throw TimeoutError(seconds: safeSeconds, reason: "Timed out")
        }
        guard let result = try await group.next() else {
            throw TimeoutError(seconds: safeSeconds, reason: "No result returned")
        }
        group.cancelAll()
        return result
    }
}

private struct ClosureClient: ThinkingSessionClient {
    let respond: @Sendable (String, ThinkingSession.Configuration) async throws -> String

    func generateResponse(for prompt: String, configuration: ThinkingSession.Configuration) async throws -> String {
        try await respond(prompt, configuration)
    }
}

#if canImport(FoundationModels)
@available(iOS 26, macOS 15, visionOS 26, *)
public struct FoundationModelsClient: StreamingThinkingSessionClient {
    private let session: LanguageModelSession

    public init(session: LanguageModelSession) {
        self.session = session
    }

    public func generateResponse(for prompt: String, configuration: ThinkingSession.Configuration) async throws -> String {
        let response = try await session.respond(to: prompt)
        return response.content
    }

    public func streamResponse(
        for prompt: String,
        configuration: ThinkingSession.Configuration
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await session.respond(to: prompt)
                    continuation.yield(response.content)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    public func generateStructuredResponse<T: Generable>(
        for prompt: String,
        configuration: ThinkingSession.Configuration,
        outputType: T.Type
    ) async throws -> T {
        try await session.respond(to: prompt, generating: outputType)
    }
}

@available(iOS 26, macOS 15, visionOS 26, *)
public extension ThinkingSession {
    init(
        session: LanguageModelSession,
        configuration: Configuration = Configuration(),
        options: ThinkingOptions = ThinkingOptions(),
        prompts: PromptTemplates = .default,
        executableTools: [ExecutableTool] = []
    ) {
        self.init(
            configuration: configuration,
            options: options,
            prompts: prompts,
            executableTools: executableTools,
            client: FoundationModelsClient(session: session)
        )
    }
}
#endif
