import Foundation

/// Prompt templates for various thinking strategies
public struct PromptTemplates {
    
    // MARK: - Chain of Thought
    
    public static let chainOfThought = """
    Think step by step about this request. For each step:
    1. Describe what you're analyzing
    2. Explain your reasoning
    3. Rate your confidence (High/Medium/Low)
    
    Show all reasoning before providing the final answer.
    """
    
    public static func chainOfThoughtPrompt(for userRequest: String) -> String {
        """
        User Request: \(userRequest)
        
        \(chainOfThought)
        
        Format your response as:
        Step 1: [Description]
        Reasoning: [Your reasoning]
        Confidence: [High/Medium/Low]
        
        Step 2: ...
        
        Final Answer: [Your response]
        """
    }
    
    // MARK: - Intent Analysis
    
    public static func intentAnalysisPrompt(for userRequest: String) -> String {
        """
        Analyze the user's request and identify:
        
        User Request: \(userRequest)
        
        1. Primary Intent: What does the user want to accomplish?
        2. Key Elements: What are the important parts of this request?
        3. Potential Ambiguities: What might be unclear or need clarification?
        4. Confidence: How confident are you in this interpretation? (High/Medium/Low)
        
        Provide your analysis in this format:
        Primary Intent: [intent]
        Key Elements: [element1, element2, element3]
        Ambiguities: [if any]
        Confidence: [level]
        """
    }
    
    // MARK: - Prompt Refinement
    
    public static func promptRefinementTemplate(for originalPrompt: String) -> String {
        """
        Refine the following user prompt for clarity and effectiveness:
        
        Original: \(originalPrompt)
        
        Consider:
        - Is the intent clear?
        - Are there ambiguities?
        - What key context is needed?
        - How can it be more specific?
        
        Refined Prompt: [Your improved version]
        
        Changes Made:
        - [List key improvements]
        """
    }
    
    // MARK: - Self-Reflection
    
    public static func reflectionPrompt(for draftResponse: String) -> String {
        """
        Review your draft response and critique it:
        
        Draft: \(draftResponse)
        
        Consider:
        1. Is this accurate? Why or why not?
        2. Are there any errors or oversights?
        3. Could it be clearer or more complete?
        4. What improvements would you make?
        
        Provide:
        Assessment: [Your critique]
        Issues Found: [List any problems]
        Revised Answer: [Improved version if needed]
        Confidence: [High/Medium/Low]
        """
    }
    
    // MARK: - Decomposition
    
    public static func decompositionPrompt(for complexRequest: String) -> String {
        """
        Break down this complex request into 3-5 manageable steps:
        
        Request: \(complexRequest)
        
        For each step, explain:
        1. What needs to be done
        2. Why this step is necessary
        3. What information it provides
        
        Format:
        Step 1: [Description]
        Purpose: [Why this step]
        
        Step 2: ...
        """
    }
    
    // MARK: - Tool Calling with Rationale
    
    public static func toolCallRationalePrompt(
        toolName: String,
        toolDescription: String,
        for context: String
    ) -> String {
        """
        Context: \(context)
        
        Consider using tool: \(toolName)
        Description: \(toolDescription)
        
        Explain:
        1. Why would you use this tool?
        2. What assumption are you verifying?
        3. What information will it provide?
        4. How will you use the result?
        
        Format:
        Reasoning: [Why use this tool]
        Expected Outcome: [What you expect to learn]
        Next Steps: [How to use the result]
        """
    }
    
    // MARK: - Alternatives Exploration
    
    public static func alternativesExplorationPrompt(for request: String) -> String {
        """
        Explore multiple approaches to this request:
        
        Request: \(request)
        
        Consider 2-3 different approaches:
        
        Approach A:
        Description: [What this approach does]
        Pros: [Benefits]
        Cons: [Drawbacks]
        
        Approach B:
        Description: [What this approach does]
        Pros: [Benefits]
        Cons: [Drawbacks]
        
        Decision: [Which approach to use and why]
        """
    }
    
    // MARK: - Self-Consistency Voting
    
    public static let selfConsistencyPrompt = """
    Generate an independent reasoning path for this request.
    Think through it from scratch without considering previous attempts.
    Show your step-by-step reasoning and arrive at an answer.
    """
    
    public static func votingPrompt(for responses: [String]) -> String {
        let numberedResponses = responses.enumerated().map { (index, response) in
            "Response \(index + 1):\n\(response)\n"
        }.joined(separator: "\n")
        
        return """
        Review these \(responses.count) independent reasoning paths:
        
        \(numberedResponses)
        
        Analyze:
        1. Which responses agree on the answer?
        2. Which reasoning is most sound?
        3. Are there any errors in the reasoning?
        
        Select the best response and explain why:
        Selected: [Response number]
        Reasoning: [Why this is the best answer]
        Confidence: [High/Medium/Low]
        """
    }
    
    // MARK: - Recursive Refinement
    
    public static func refinementFeedbackPrompt(
        originalRequest: String,
        currentAnswer: String,
        iteration: Int
    ) -> String {
        """
        Refinement Iteration \(iteration)
        
        Original Request: \(originalRequest)
        Current Answer: \(currentAnswer)
        
        Evaluate:
        1. Does this fully address the request?
        2. Are there gaps or inaccuracies?
        3. How can it be improved?
        
        Provide:
        Assessment: [Your evaluation]
        Improvements Needed: [Specific changes]
        Refined Answer: [Improved version]
        Should Continue: [Yes/No - is further refinement needed?]
        """
    }
    
    // MARK: - Error Recovery
    
    public static func errorRecoveryPrompt(
        error: String,
        context: String
    ) -> String {
        """
        An error occurred during processing:
        
        Error: \(error)
        Context: \(context)
        
        Analyze:
        1. Why did this fail?
        2. What alternative approach can we try?
        3. What information do we need?
        
        Provide:
        Root Cause: [Why it failed]
        Alternative Approach: [What to try instead]
        Confidence: [High/Medium/Low in the alternative]
        """
    }
    
    // MARK: - Structured Output Schema
    
    public static let structuredResponseSchema = """
    {
      "intent_analysis": {
        "primary_intent": "string",
        "key_elements": ["string"],
        "ambiguities": ["string"],
        "confidence": 0.85
      },
      "reasoning_trace": [
        {
          "step": 1,
          "description": "string",
          "rationale": "string",
          "confidence": 0.90
        }
      ],
      "decisions_explained": [
        {
          "decision": "string",
          "reasoning": "string",
          "confidence": 0.88
        }
      ],
      "final_answer": "string",
      "overall_confidence": 0.92
    }
    """
    
    public static func structuredOutputPrompt(for request: String) -> String {
        """
        Respond to this request using structured JSON format:
        
        Request: \(request)
        
        Use this schema:
        \(structuredResponseSchema)
        
        Include all reasoning steps and explanations in the structured format.
        """
    }
    
    // MARK: - Confidence Scoring
    
    public static let confidenceScoringGuidelines = """
    Rate your confidence for each step:
    
    High: You're very confident in this reasoning (90%+ certainty)
    Medium: You're moderately confident (60-90% certainty)
    Low: You're uncertain or need more information (<60% certainty)
    
    Always explain WHY you have this confidence level.
    """
    
    // MARK: - Full Thinking Mode
    
    public static func fullThinkingPrompt(for userRequest: String) -> String {
        """
        Process this request with maximum thinking depth:
        
        User Request: \(userRequest)
        
        1. INTENT ANALYSIS
           - What does the user want?
           - Key elements?
           - Ambiguities?
        
        2. PROMPT REFINEMENT
           - How can we clarify this request?
        
        3. DECOMPOSITION
           - Break into steps
        
        4. REASONING
           - Think step-by-step
           - Show all reasoning
           - Include confidence levels
        
        5. ALTERNATIVES
           - Consider different approaches
           - Evaluate pros/cons
        
        6. DECISIONS
           - Explain each decision
        
        7. REFLECTION
           - Critique your answer
           - Identify improvements
        
        8. FINAL ANSWER
           - Refined response
        
        Be thorough and show all your thinking.
        """
    }
    
    // MARK: - Light Thinking Mode
    
    public static func lightThinkingPrompt(for userRequest: String) -> String {
        """
        User Request: \(userRequest)
        
        Think briefly about this request:
        1. What's being asked?
        2. Key reasoning steps?
        3. Answer?
        
        Keep it concise but show your reasoning.
        """
    }
}
