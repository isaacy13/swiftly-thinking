import Foundation
import SwiftlyThinking

@main
struct ThinkingDemo {
    static func main() async {
        print("🧠 SwiftlyThinking Demo")
        print("=" * 50)
        print()
        
        do {
            // Demo 1: Chain-of-Thought Reasoning
            print("📝 Demo 1: Chain-of-Thought Reasoning")
            print("-" * 50)
            try await demoChainOfThought()
            print()
            
            // Demo 2: Light vs Deep Thinking
            print("⚡ Demo 2: Light vs Deep Thinking")
            print("-" * 50)
            try await demoLightVsDeep()
            print()
            
            // Demo 3: Self-Consistency
            print("✅ Demo 3: Self-Consistency with Multiple Paths")
            print("-" * 50)
            try await demoSelfConsistency()
            print()
            
            // Demo 4: Intent Analysis
            print("🎯 Demo 4: Intent Analysis")
            print("-" * 50)
            try await demoIntentAnalysis()
            print()
            
            // Demo 5: Alternative Exploration
            print("🔍 Demo 5: Exploring Alternatives")
            print("-" * 50)
            try await demoAlternatives()
            print()
            
            // Demo 6: JSON Serialization
            print("📄 Demo 6: JSON Serialization")
            print("-" * 50)
            try await demoJSONSerialization()
            print()
            
            print("✨ Demo completed successfully!")
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    static func demoChainOfThought() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(strategy: .chainOfThought)
        )
        
        let response = try await session.thinkAndRespond(
            to: "What is the Fibonacci sequence?"
        )
        
        print("Question: What is the Fibonacci sequence?")
        print()
        print("Reasoning Steps:")
        for step in response.reasoningTrace {
            print("  \(step.stepNumber). \(step.description)")
            print("     Rationale: \(step.rationale)")
            if let confidence = step.confidence {
                print("     Confidence: \(confidence.rawValue) (\(confidence.numericValue))")
            }
        }
        print()
        print("Answer: \(response.finalAnswer)")
        print("Overall Confidence: \(response.overallConfidence ?? 0.0)")
    }
    
    static func demoLightVsDeep() async throws {
        let lightSession = ThinkingSession(configuration: .light)
        let deepSession = ThinkingSession(configuration: .deep)
        
        let question = "Explain machine learning"
        
        let lightResponse = try await lightSession.thinkAndRespond(to: question)
        let deepResponse = try await deepSession.thinkAndRespond(to: question)
        
        print("Question: \(question)")
        print()
        print("Light Mode:")
        print("  Strategy: \(lightResponse.metadata.strategy)")
        print("  Iterations: \(lightResponse.metadata.iterations)")
        print("  Reasoning Steps: \(lightResponse.reasoningTrace.count)")
        print("  Processing Time: \(lightResponse.metadata.processingTime ?? 0.0)s")
        print()
        print("Deep Mode:")
        print("  Strategy: \(deepResponse.metadata.strategy)")
        print("  Iterations: \(deepResponse.metadata.iterations)")
        print("  Reasoning Steps: \(deepResponse.reasoningTrace.count)")
        print("  Has Intent Analysis: \(deepResponse.intentAnalysis != nil)")
        print("  Has Alternatives: \(deepResponse.alternativesConsidered != nil)")
        print("  Processing Time: \(deepResponse.metadata.processingTime ?? 0.0)s")
    }
    
    static func demoSelfConsistency() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(
                strategy: .selfConsistency,
                parallelPaths: 5
            )
        )
        
        let response = try await session.thinkAndRespond(
            to: "What is 25 × 4?"
        )
        
        print("Question: What is 25 × 4?")
        print()
        print("Strategy: Self-Consistency")
        print("Parallel Paths: \(response.metadata.parallelPaths ?? 0)")
        print()
        print("Reasoning Process:")
        for step in response.reasoningTrace {
            print("  Step \(step.stepNumber): \(step.description)")
            if let details = step.details {
                for detail in details {
                    print("    • \(detail)")
                }
            }
        }
        print()
        print("Answer: \(response.finalAnswer)")
        print("Confidence: \(response.overallConfidence ?? 0.0)")
    }
    
    static func demoIntentAnalysis() async throws {
        let session = ThinkingSession()
        
        let queries = [
            "I need to book a flight to Paris next month",
            "Find me restaurants nearby",
            "How do I fix my broken code?"
        ]
        
        for query in queries {
            let intent = try await session.analyzeIntent(userPrompt: query)
            
            print("Query: \"\(query)\"")
            print("  Primary Intent: \(intent.primaryIntent)")
            print("  Key Elements: \(intent.keyElements.joined(separator: ", "))")
            if let ambiguities = intent.ambiguities, !ambiguities.isEmpty {
                print("  Ambiguities: \(ambiguities.joined(separator: ", "))")
            }
            if let confidence = intent.confidence {
                print("  Confidence: \(confidence)")
            }
            print()
        }
    }
    
    static func demoAlternatives() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(strategy: .exploration)
        )
        
        let response = try await session.thinkAndRespond(
            to: "What's the best way to learn programming?"
        )
        
        print("Question: What's the best way to learn programming?")
        print()
        
        if let alternatives = response.alternativesConsidered {
            print("Alternatives Considered:")
            for (index, alt) in alternatives.enumerated() {
                print("  \(index + 1). \(alt.description)")
                print("     Pros: \(alt.pros.joined(separator: ", "))")
                print("     Cons: \(alt.cons.joined(separator: ", "))")
                print("     Chosen: \(alt.chosen ? "✓" : "✗")")
                print("     Reasoning: \(alt.reasoning)")
                print()
            }
        }
        
        print("Final Answer: \(response.finalAnswer)")
    }
    
    static func demoJSONSerialization() async throws {
        let session = ThinkingSession(
            configuration: ThinkingConfiguration(
                strategy: .chainOfThought,
                useStructuredOutputs: true
            )
        )
        
        let response = try await session.thinkAndRespond(
            to: "What are the benefits of exercise?"
        )
        
        print("Serializing response to JSON...")
        print()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(response)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            // Print first 1000 characters to avoid overwhelming output
            let preview = String(jsonString.prefix(1000))
            print(preview)
            if jsonString.count > 1000 {
                print("... (truncated, total \(jsonString.count) characters)")
            }
        }
        
        // Test deserialization
        let decoded = try JSONDecoder().decode(ReasonedResponse.self, from: jsonData)
        print()
        print("✓ Successfully serialized and deserialized!")
        print("  Original request: \(decoded.originalRequest)")
        print("  Reasoning steps: \(decoded.reasoningTrace.count)")
        print("  Strategy: \(decoded.metadata.strategy)")
    }
}

// String multiplication helper
extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}
