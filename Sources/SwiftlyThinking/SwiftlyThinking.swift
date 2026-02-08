import Foundation

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

public enum ConfidenceLevel: String, Codable, Sendable {
    case high
    case medium
    case low
    case unknown
}

public struct ThinkingOptions: Codable, Sendable, Equatable {
    public var strategy: ThinkingStrategy
    public var mode: ThinkingMode
    public var maxRefinementIterations: Int
    public var selfConsistencySamples: Int
    public var maxDecompositionSteps: Int

    public init(
        strategy: ThinkingStrategy = .cot,
        mode: ThinkingMode = .light,
        maxRefinementIterations: Int = 1,
        selfConsistencySamples: Int = 1,
        maxDecompositionSteps: Int = 4
    ) {
        self.strategy = strategy
        self.mode = mode
        self.maxRefinementIterations = max(1, maxRefinementIterations)
        self.selfConsistencySamples = max(1, selfConsistencySamples)
        self.maxDecompositionSteps = max(1, maxDecompositionSteps)
    }
}

public struct ThinkingTool: Codable, Sendable, Equatable {
    public var name: String
    public var description: String
    public var parametersSchema: String?

    public init(name: String, description: String, parametersSchema: String? = nil) {
        self.name = name
        self.description = description
        self.parametersSchema = parametersSchema
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

public struct ReasonedResponse: Codable, Sendable, Equatable {
    public var intentAnalysis: String
    public var refinedPrompt: String?
    public var reasoningTrace: [String]
    public var decisionsExplained: [String]
    public var alternatives: [String]
    public var reflection: String?
    public var toolRationale: String?
    public var selectionRationale: String?
    public var finalAnswer: String
    public var confidence: ConfidenceLevel

    public init(
        intentAnalysis: String,
        refinedPrompt: String? = nil,
        reasoningTrace: [String] = [],
        decisionsExplained: [String] = [],
        alternatives: [String] = [],
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
        self.reflection = reflection
        self.toolRationale = toolRationale
        self.selectionRationale = selectionRationale
        self.finalAnswer = finalAnswer
        self.confidence = confidence
    }

    public static let jsonSchema: String = """
    {
      "type": "object",
      "properties": {
        "intent_analysis": { "type": "string" },
        "refined_prompt": { "type": ["string", "null"] },
        "reasoning_trace": { "type": "array", "items": { "type": "string" } },
        "decisions_explained": { "type": "array", "items": { "type": "string" } },
        "alternatives": { "type": "array", "items": { "type": "string" } },
        "reflection": { "type": ["string", "null"] },
        "tool_rationale": { "type": ["string", "null"] },
        "selection_rationale": { "type": ["string", "null"] },
        "final_answer": { "type": "string" },
        "confidence": { "type": "string", "enum": ["high", "medium", "low", "unknown"] }
      },
      "required": ["intent_analysis", "reasoning_trace", "decisions_explained", "final_answer", "confidence"]
    }
    """

    private enum CodingKeys: String, CodingKey {
        case intentAnalysis = "intent_analysis"
        case refinedPrompt = "refined_prompt"
        case reasoningTrace = "reasoning_trace"
        case decisionsExplained = "decisions_explained"
        case alternatives
        case reflection
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
        reflection = try container.decodeIfPresent(String.self, forKey: .reflection)
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
        try container.encode(reflection, forKey: .reflection)
        try container.encode(toolRationale, forKey: .toolRationale)
        try container.encode(selectionRationale, forKey: .selectionRationale)
        try container.encode(finalAnswer, forKey: .finalAnswer)
        try container.encode(confidence, forKey: .confidence)
    }
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
        Think step by step. Intent: {intent}. Tools: {tools}.\nReturn JSON that matches this schema: {schema}\nPrompt: {prompt}
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
        Review the draft response for accuracy, gaps, or weak reasoning. Revise as needed and explain the changes.\nDraft: {draft}
        """,
        alternatives: """
        Explore alternative perspectives, pros/cons, and tradeoffs for: {prompt}\nProvide a short comparison.
        """,
        toolRationale: """
        If tools are available, explain which tool you would call and why. Tools: {tools}\nPrompt: {prompt}
        """,
        selfConsistency: """
        Generate an independent reasoning path. Return JSON that matches this schema: {schema}\nPrompt: {prompt}
        """
    )
}

public enum ThinkingSessionError: Error {
    case emptyResponse
    case unableToParseStructuredOutput
}

public protocol ThinkingSessionClient: Sendable {
    func generateResponse(for prompt: String, configuration: ThinkingSession.Configuration) async throws -> String
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

    public var configuration: Configuration
    public var options: ThinkingOptions
    public var prompts: PromptTemplates
    public private(set) var transcript: [TranscriptEntry]

    private let client: any ThinkingSessionClient

    public init(
        configuration: Configuration = Configuration(),
        options: ThinkingOptions = ThinkingOptions(),
        prompts: PromptTemplates = .default,
        client: some ThinkingSessionClient
    ) {
        self.configuration = configuration
        self.options = options
        self.prompts = prompts
        self.client = client
        self.transcript = configuration.transcript
    }

    public init(
        configuration: Configuration = Configuration(),
        options: ThinkingOptions = ThinkingOptions(),
        prompts: PromptTemplates = .default,
        respond: @escaping @Sendable (String, Configuration) async throws -> String
    ) {
        self.init(configuration: configuration, options: options, prompts: prompts, client: ClosureClient(respond: respond))
    }

    public mutating func thinkAndRespond(
        to userPrompt: String,
        strategy: ThinkingStrategy? = nil
    ) async throws -> ReasonedResponse {
        let strategy = strategy ?? options.strategy
        let profile = profileFor(strategy: strategy)
        let basePrompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        appendEntry(role: .user, content: basePrompt)

        var refinedPrompt = basePrompt
        if profile.includesRefinement {
            refinedPrompt = try await refinePrompt(original: basePrompt)
        }

        var intentAnalysis = ""
        if profile.includesIntent {
            intentAnalysis = try await analyzeIntent(for: refinedPrompt)
        }

        var reasoningTrace: [String] = []
        var decisions: [String] = []
        var alternatives: [String] = []
        var toolRationale: String? = nil

        if profile.includesAlternatives {
            let alternative = try await exploreAlternatives(for: refinedPrompt)
            alternatives.append(alternative)
            reasoningTrace.append(alternative)
        }

        if profile.includesToolRationale {
            toolRationale = try await explainToolRationale(for: refinedPrompt)
            if let toolRationale {
                reasoningTrace.append(toolRationale)
            }
        }

        if profile.includesDecomposition {
            let decomposition = try await decomposeAndChain(complexPrompt: refinedPrompt)
            reasoningTrace.append(decomposition)
            decisions.append("Decomposed the request into sequenced steps for clarity.")
        }

        var draft = try await generateDraft(prompt: refinedPrompt, intent: intentAnalysis)
        reasoningTrace.append(draft)

        var reflectionNote: String? = nil
        if profile.includesReflection {
            for _ in 0..<options.maxRefinementIterations {
                let reflection = try await reflectOnDraft(draft)
                reflectionNote = reflection.note
                draft = reflection.revised
            }
            if let reflectionNote {
                reasoningTrace.append(reflectionNote)
            }
        }

        var selectionRationale: String? = nil
        if profile.includesSelfConsistency && options.selfConsistencySamples > 1 {
            let selection = try await chooseSelfConsistentAnswer(prompt: refinedPrompt, intent: intentAnalysis)
            draft = selection.answer
            alternatives.append(contentsOf: selection.candidates)
            selectionRationale = selection.rationale
        }

        let response = parseReasonedResponse(from: draft, defaultIntent: intentAnalysis, refinedPrompt: refinedPrompt)
        let finalResponse = ReasonedResponse(
            intentAnalysis: response.intentAnalysis,
            refinedPrompt: response.refinedPrompt ?? refinedPrompt,
            reasoningTrace: mergeUnique(response.reasoningTrace, reasoningTrace),
            decisionsExplained: mergeUnique(response.decisionsExplained, decisions),
            alternatives: mergeUnique(response.alternatives, alternatives),
            reflection: response.reflection ?? reflectionNote,
            toolRationale: response.toolRationale ?? toolRationale,
            selectionRationale: response.selectionRationale ?? selectionRationale,
            finalAnswer: response.finalAnswer,
            confidence: response.confidence
        )

        appendEntry(role: .assistant, content: finalResponse.finalAnswer)
        return finalResponse
    }

    public mutating func refinePrompt(original: String) async throws -> String {
        let prompt = render(prompts.refinement, values: ["prompt": original])
        let response = try await requestResponse(prompt, note: "Refining prompt")
        return response
    }

    public mutating func analyzeIntent(for promptText: String) async throws -> String {
        let prompt = render(prompts.intentAnalysis, values: ["prompt": promptText])
        return try await requestResponse(prompt, note: "Analyzing intent")
    }

    public mutating func decomposeAndChain(complexPrompt: String) async throws -> String {
        let prompt = render(prompts.decomposition, values: [
            "prompt": complexPrompt,
            "max_steps": "\(options.maxDecompositionSteps)"
        ])
        let decomposition = try await requestResponse(prompt, note: "Decomposing request")
        let steps = extractSteps(from: decomposition)

        var stepResults: [String] = []
        for (index, step) in steps.enumerated() {
            let stepPrompt = render(prompts.solveStep, values: [
                "step_index": "\(index + 1)",
                "step": step
            ])
            let result = try await requestResponse(stepPrompt, note: "Solving step \(index + 1)")
            stepResults.append(result)
        }

        let recombinePrompt = render(prompts.recombine, values: [
            "steps": steps.joined(separator: "\n"),
            "results": stepResults.joined(separator: "\n")
        ])
        let recombined = try await requestResponse(recombinePrompt, note: "Recombining steps")
        return """
        Decomposition:\n\(decomposition)\n\nStep Results:\n\(stepResults.joined(separator: "\n"))\n\nRecombined Answer:\n\(recombined)
        """
    }

    public mutating func reflectOnDraft(_ draft: String) async throws -> (note: String, revised: String) {
        let prompt = render(prompts.reflection, values: ["draft": draft])
        let reflection = try await requestResponse(prompt, note: "Reflecting on draft")
        return (note: reflection, revised: reflection)
    }

    public mutating func exploreAlternatives(for promptText: String) async throws -> String {
        let prompt = render(prompts.alternatives, values: ["prompt": promptText])
        return try await requestResponse(prompt, note: "Exploring alternatives")
    }

    public mutating func explainToolRationale(for promptText: String) async throws -> String? {
        guard !configuration.tools.isEmpty else { return nil }
        let prompt = render(prompts.toolRationale, values: [
            "prompt": promptText,
            "tools": toolSummary()
        ])
        return try await requestResponse(prompt, note: "Explaining tool rationale")
    }

    private mutating func generateDraft(prompt: String, intent: String) async throws -> String {
        let schema = configuration.generationSchema ?? ReasonedResponse.jsonSchema
        let promptText = render(prompts.chainOfThought, values: [
            "prompt": prompt,
            "intent": intent.isEmpty ? "No explicit intent analysis" : intent,
            "tools": toolSummary(),
            "schema": schema
        ])
        return try await requestResponse(promptText, note: "Generating draft")
    }

    private mutating func chooseSelfConsistentAnswer(
        prompt: String,
        intent: String
    ) async throws -> (answer: String, candidates: [String], rationale: String) {
        let schema = configuration.generationSchema ?? ReasonedResponse.jsonSchema
        var candidates: [String] = []
        for index in 0..<options.selfConsistencySamples {
            let promptText = render(prompts.selfConsistency, values: [
                "prompt": "(Path \(index + 1)) \(prompt)",
                "schema": schema
            ])
            let response = try await requestResponse(promptText, note: "Self-consistency path \(index + 1)")
            let parsed = parseReasonedResponse(from: response, defaultIntent: intent, refinedPrompt: nil)
            candidates.append(parsed.finalAnswer)
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

    private mutating func requestResponse(_ prompt: String, note: String) async throws -> String {
        let wrappedPrompt = wrapPrompt(prompt)
        appendEntry(role: .thinking, content: note, metadata: ["prompt": wrappedPrompt])
        let response = try await client.generateResponse(for: wrappedPrompt, configuration: currentConfiguration())
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ThinkingSessionError.emptyResponse }
        appendEntry(role: .thinking, content: trimmed)
        return trimmed
    }

    private func wrapPrompt(_ prompt: String) -> String {
        var header: [String] = []
        if let instructions = configuration.instructions, !instructions.isEmpty {
            header.append("System instructions: \(instructions)")
        }
        if !configuration.tools.isEmpty {
            header.append("Available tools:\n\(toolSummary())")
        }
        return (header + [prompt]).joined(separator: "\n\n")
    }

    private func toolSummary() -> String {
        guard !configuration.tools.isEmpty else { return "None" }
        return configuration.tools.map { tool in
            var line = "- \(tool.name): \(tool.description)"
            if let schema = tool.parametersSchema {
                line += " (schema: \(schema))"
            }
            return line
        }.joined(separator: "\n")
    }

    private func currentConfiguration() -> Configuration {
        var updated = configuration
        updated.transcript = transcript
        return updated
    }

    private mutating func appendEntry(role: TranscriptEntry.Role, content: String, metadata: [String: String]? = nil) {
        transcript.append(TranscriptEntry(role: role, content: content, metadata: metadata))
    }

    private func parseReasonedResponse(
        from raw: String,
        defaultIntent: String,
        refinedPrompt: String?
    ) -> ReasonedResponse {
        if let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(ReasonedResponse.self, from: data) {
            return decoded
        }

        return ReasonedResponse(
            intentAnalysis: defaultIntent,
            refinedPrompt: refinedPrompt,
            reasoningTrace: [raw],
            decisionsExplained: [],
            alternatives: [],
            reflection: nil,
            toolRationale: nil,
            selectionRationale: nil,
            finalAnswer: raw,
            confidence: .unknown
        )
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

private struct ClosureClient: ThinkingSessionClient {
    let respond: @Sendable (String, ThinkingSession.Configuration) async throws -> String

    func generateResponse(for prompt: String, configuration: ThinkingSession.Configuration) async throws -> String {
        try await respond(prompt, configuration)
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 15, visionOS 26, *)
public struct FoundationModelsClient: ThinkingSessionClient {
    private let session: LanguageModelSession

    public init(session: LanguageModelSession) {
        self.session = session
    }

    public func generateResponse(for prompt: String, configuration: ThinkingSession.Configuration) async throws -> String {
        let response = try await session.respond(to: prompt)
        return response.content
    }
}

@available(iOS 26, macOS 15, visionOS 26, *)
public extension ThinkingSession {
    init(
        session: LanguageModelSession,
        configuration: Configuration = Configuration(),
        options: ThinkingOptions = ThinkingOptions(),
        prompts: PromptTemplates = .default
    ) {
        self.init(configuration: configuration, options: options, prompts: prompts, client: FoundationModelsClient(session: session))
    }
}
#endif
