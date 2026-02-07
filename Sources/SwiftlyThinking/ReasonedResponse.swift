import Foundation

/// A structured response that includes reasoning traces and explanations
public struct ReasonedResponse: Codable, Sendable {
    /// The user's original request or query
    public let originalRequest: String
    
    /// Analyzed user intent and key elements
    public let intentAnalysis: IntentAnalysis?
    
    /// Step-by-step reasoning trace showing the model's thought process
    public let reasoningTrace: [ReasoningStep]
    
    /// Decisions made during processing with explanations
    public let decisionsExplained: [Decision]
    
    /// Tool calls made with rationale
    public let toolCalls: [ToolCallRationale]?
    
    /// Alternative perspectives or approaches considered
    public let alternativesConsidered: [Alternative]?
    
    /// The final answer or response
    public let finalAnswer: String
    
    /// Overall confidence in the response (0.0 to 1.0)
    public let overallConfidence: Double?
    
    /// Metadata about the thinking process
    public let metadata: ThinkingMetadata
    
    public init(
        originalRequest: String,
        intentAnalysis: IntentAnalysis?,
        reasoningTrace: [ReasoningStep],
        decisionsExplained: [Decision],
        toolCalls: [ToolCallRationale]? = nil,
        alternativesConsidered: [Alternative]? = nil,
        finalAnswer: String,
        overallConfidence: Double? = nil,
        metadata: ThinkingMetadata
    ) {
        self.originalRequest = originalRequest
        self.intentAnalysis = intentAnalysis
        self.reasoningTrace = reasoningTrace
        self.decisionsExplained = decisionsExplained
        self.toolCalls = toolCalls
        self.alternativesConsidered = alternativesConsidered
        self.finalAnswer = finalAnswer
        self.overallConfidence = overallConfidence
        self.metadata = metadata
    }
}

/// Analysis of user intent
public struct IntentAnalysis: Codable, Sendable {
    /// What the user likely wants to accomplish
    public let primaryIntent: String
    
    /// Key elements identified in the request
    public let keyElements: [String]
    
    /// Potential ambiguities or clarifications needed
    public let ambiguities: [String]?
    
    /// Confidence in the intent analysis (0.0 to 1.0)
    public let confidence: Double?
    
    public init(
        primaryIntent: String,
        keyElements: [String],
        ambiguities: [String]? = nil,
        confidence: Double? = nil
    ) {
        self.primaryIntent = primaryIntent
        self.keyElements = keyElements
        self.ambiguities = ambiguities
        self.confidence = confidence
    }
}

/// A single step in the reasoning process
public struct ReasoningStep: Codable, Sendable {
    /// Step number in the sequence
    public let stepNumber: Int
    
    /// Description of what's being considered
    public let description: String
    
    /// The reasoning or rationale for this step
    public let rationale: String
    
    /// Confidence level for this step
    public let confidence: ConfidenceLevel?
    
    /// Any sub-steps or details
    public let details: [String]?
    
    public init(
        stepNumber: Int,
        description: String,
        rationale: String,
        confidence: ConfidenceLevel? = nil,
        details: [String]? = nil
    ) {
        self.stepNumber = stepNumber
        self.description = description
        self.rationale = rationale
        self.confidence = confidence
        self.details = details
    }
}

/// Confidence level for reasoning steps
public enum ConfidenceLevel: String, Codable, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    /// Numeric value for aggregation (0.0 to 1.0)
    public var numericValue: Double {
        switch self {
        case .high: return 0.9
        case .medium: return 0.6
        case .low: return 0.3
        }
    }
}

/// A decision made during processing
public struct Decision: Codable, Sendable {
    /// What decision was made
    public let decision: String
    
    /// Why this decision was made
    public let reasoning: String
    
    /// Confidence in this decision
    public let confidence: ConfidenceLevel?
    
    public init(
        decision: String,
        reasoning: String,
        confidence: ConfidenceLevel? = nil
    ) {
        self.decision = decision
        self.reasoning = reasoning
        self.confidence = confidence
    }
}

/// Rationale for a tool call
public struct ToolCallRationale: Codable, Sendable {
    /// Name of the tool being called
    public let toolName: String
    
    /// Why this tool is being used
    public let reasoning: String
    
    /// What the tool should help accomplish
    public let expectedOutcome: String
    
    /// Parameters passed to the tool
    public let parameters: [String: String]?
    
    public init(
        toolName: String,
        reasoning: String,
        expectedOutcome: String,
        parameters: [String: String]? = nil
    ) {
        self.toolName = toolName
        self.reasoning = reasoning
        self.expectedOutcome = expectedOutcome
        self.parameters = parameters
    }
}

/// An alternative approach that was considered
public struct Alternative: Codable, Sendable {
    /// Description of the alternative
    public let description: String
    
    /// Pros of this approach
    public let pros: [String]
    
    /// Cons of this approach
    public let cons: [String]
    
    /// Whether this alternative was chosen
    public let chosen: Bool
    
    /// Reason for choosing or rejecting
    public let reasoning: String
    
    public init(
        description: String,
        pros: [String],
        cons: [String],
        chosen: Bool,
        reasoning: String
    ) {
        self.description = description
        self.pros = pros
        self.cons = cons
        self.chosen = chosen
        self.reasoning = reasoning
    }
}

/// Metadata about the thinking process
public struct ThinkingMetadata: Codable, Sendable {
    /// Strategy used
    public let strategy: ThinkingStrategy
    
    /// Number of iterations performed
    public let iterations: Int
    
    /// Number of reasoning paths generated (for self-consistency)
    public let parallelPaths: Int?
    
    /// Processing time in seconds
    public let processingTime: Double?
    
    /// Any errors or warnings encountered
    public let errors: [String]?
    
    public init(
        strategy: ThinkingStrategy,
        iterations: Int,
        parallelPaths: Int? = nil,
        processingTime: Double? = nil,
        errors: [String]? = nil
    ) {
        self.strategy = strategy
        self.iterations = iterations
        self.parallelPaths = parallelPaths
        self.processingTime = processingTime
        self.errors = errors
    }
}
