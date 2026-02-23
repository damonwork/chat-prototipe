import Foundation

final class BotResponseService {
    static let shared = BotResponseService()

    private let motivationalReplies = [
        "You are making progress, even on the hard days.",
        "Small steps still move you forward. Keep going.",
        "You have handled difficult things before, and you can do it again.",
        "Your effort today matters more than perfection.",
        "Take a breath. You are doing better than you think."
    ]

    private let keywordReplies: [(keywords: [String], reply: String)] = [
        (["sad", "down", "depressed", "bad day"], "I am sorry you are feeling this way. Want to share what happened?"),
        (["anxious", "anxiety", "nervous", "stress"], "That sounds stressful. Try one slow breath in and out with me first."),
        (["happy", "great", "awesome", "good news"], "That is great to hear. I am happy for you."),
        (["tired", "exhausted", "burnout"], "You might need a short break. Rest is productive too."),
        (["motivate", "motivation", "focus", "discipline"], "Start with one tiny task now. Momentum beats overthinking.")
    ]

    private init() {}

    func buildReply(for input: String) -> String {
        let normalized = input.lowercased()
        for rule in keywordReplies {
            if rule.keywords.contains(where: { normalized.contains($0) }) {
                return rule.reply
            }
        }

        if normalized.contains("hello") || normalized.contains("hi") {
            return "Hey there. I am here for you. How are you feeling right now?"
        }
        if normalized.contains("thank") {
            return "You are welcome. I am glad I could help."
        }

        return motivationalReplies.randomElement() ?? "Keep going. You have this."
    }
}
