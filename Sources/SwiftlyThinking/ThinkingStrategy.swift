import Foundation

/// Thinking strategies that determine how the model processes requests
public enum ThinkingStrategy: String, Codable, Sendable {
    /// Basic chain-of-thought reasoning with step-by-step explanations
    case chainOfThought = "chain_of_thought"
    
    /// Reflects on and critiques responses for self-correction
    case reflection
    
    /// Breaks complex queries into sub-tasks and solves sequentially
    case decomposition
    
    /// Generates multiple reasoning paths and votes on the best answer
    case selfConsistency = "self_consistency"
    
    /// Explores multiple perspectives and alternatives before deciding
    case exploration
    
    /// Iteratively refines responses through multiple feedback loops
    case recursiveRefinement = "recursive_refinement"
    
    /// Combines all strategies for maximum thinking depth
    case full
    
    /// Lightweight thinking for simple queries (minimal CoT)
    case light
    
    /// Custom strategy with user-defined behavior
    case custom
}

/// Configuration for thinking modes
public struct ThinkingConfiguration: Sendable {
    /// The primary thinking strategy to use
    public let strategy: ThinkingStrategy
    
    /// Maximum number of refinement iterations (for recursive strategies)
    public let maxIterations: Int
    
    /// Number of parallel reasoning paths (for self-consistency)
    public let parallelPaths: Int
    
    /// Whether to expose detailed reasoning in the output
    public let exposeReasoning: Bool
    
    /// Whether to include confidence scores in reasoning steps
    public let includeConfidence: Bool
    
    /// Whether to use structured JSON outputs
    public let useStructuredOutputs: Bool
    
    /// Custom prompt templates (optional)
    public let customPrompts: [String: String]?
    
    public init(
        strategy: ThinkingStrategy = .chainOfThought,
        maxIterations: Int = 3,
        parallelPaths: Int = 3,
        exposeReasoning: Bool = true,
        includeConfidence: Bool = true,
        useStructuredOutputs: Bool = true,
        customPrompts: [String: String]? = nil
    ) {
        self.strategy = strategy
        self.maxIterations = maxIterations
        self.parallelPaths = parallelPaths
        self.exposeReasoning = exposeReasoning
        self.includeConfidence = includeConfidence
        self.useStructuredOutputs = useStructuredOutputs
        self.customPrompts = customPrompts
    }
    
    /// Default configuration for light thinking
    public static var light: ThinkingConfiguration {
        ThinkingConfiguration(
            strategy: .light,
            maxIterations: 1,
            parallelPaths: 1,
            exposeReasoning: true,
            includeConfidence: false,
            useStructuredOutputs: false
        )
    }
    
    /// Default configuration for deep thinking
    public static var deep: ThinkingConfiguration {
        ThinkingConfiguration(
            strategy: .full,
            maxIterations: 5,
            parallelPaths: 5,
            exposeReasoning: true,
            includeConfidence: true,
            useStructuredOutputs: true
        )
    }
}
