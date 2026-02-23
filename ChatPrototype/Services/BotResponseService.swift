import Foundation

final class BotResponseService {
    static let shared = BotResponseService()

    // MARK: - Motivational fallbacks

    private let motivationalReplies = [
        "You're making progress, even on the hard days. Keep pushing! 💪",
        "Small steps still move you forward — every little bit counts. 🌱",
        "You've handled tough things before, and you'll get through this too. 🌟",
        "Your effort today matters more than perfection. Just keep going. 🔥",
        "Take a breath. You're doing better than you think. 😌",
        "Believe in yourself — the fact that you're here already shows strength! 🦁",
        "One day at a time. You've got this! ✨",
        "Progress, not perfection. You're on the right track. 🛤️",
        "You are capable of amazing things. Don't forget that! 🌠",
        "Every expert was once a beginner. Keep going! 🚀"
    ]

    // MARK: - Keyword rules

    private let keywordReplies: [(keywords: [String], replies: [String])] = [
        (
            ["sad", "down", "depressed", "unhappy", "bad day", "terrible"],
            [
                "I'm sorry you're feeling this way 💙. Want to share what's going on? I'm here to listen.",
                "That sounds really hard 😔. It's okay to feel this way — tell me more if you'd like.",
                "Sending you warmth and kindness 🤗. You don't have to go through this alone."
            ]
        ),
        (
            ["anxious", "anxiety", "nervous", "stressed", "stress", "overwhelmed", "panic"],
            [
                "That sounds stressful 😤. Take one slow, deep breath with me — in through the nose, out through the mouth. 🌬️",
                "Anxiety can be overwhelming, but you're stronger than it 💪. Let's take it one small step at a time.",
                "When everything feels too much, just focus on the next 5 minutes. You've got this 🫶."
            ]
        ),
        (
            ["happy", "great", "awesome", "excited", "amazing", "fantastic", "good news", "celebrate"],
            [
                "That's amazing! 🎉 I'm so happy for you — you deserve it!",
                "Woohoo! 🥳 That's fantastic news! Celebrate yourself today!",
                "Love hearing this! 🌟 Keep riding that positive wave!"
            ]
        ),
        (
            ["tired", "exhausted", "burnout", "drained", "no energy", "sleep"],
            [
                "Rest is not laziness — it's fuel 🔋. Give yourself permission to recharge.",
                "Your body is telling you something important. A short break now will help you more than pushing through 😴.",
                "Take care of yourself first 🛌. Even heroes need to rest!"
            ]
        ),
        (
            ["motivate", "motivation", "focus", "discipline", "productive", "goal", "help me"],
            [
                "Start with one tiny task right now — momentum beats overthinking every time 🚀.",
                "Set a 5-minute timer and just begin. You'll often find you keep going 🔥.",
                "Discipline is just doing the thing even when you don't feel like it. You've got this! 💎"
            ]
        ),
        (
            ["lonely", "alone", "nobody", "no one", "isolated"],
            [
                "You're not alone — I'm right here with you 🤝. Tell me what's on your mind.",
                "Loneliness is so hard 💙. Remember, reaching out like this takes courage. I'm listening.",
                "Connection matters. I'm glad you're here 🌸."
            ]
        ),
        (
            ["angry", "frustrated", "annoyed", "mad", "rage", "upset"],
            [
                "It's okay to feel angry sometimes 😤. What happened? I'm here to listen without judgment.",
                "Anger usually signals something important. Take a breath and let's talk through it 🌬️.",
                "Your feelings are valid. Want to share what's going on? 💬"
            ]
        ),
        (
            ["work", "job", "boss", "colleague", "office", "career"],
            [
                "Work situations can be really stressful 😅. What's going on? Tell me more.",
                "Career stuff can feel heavy. Want to talk through what's happening? I'm all ears 👂.",
                "Even small wins at work matter — celebrate them! 🏆"
            ]
        ),
        (
            ["love", "relationship", "partner", "boyfriend", "girlfriend", "breakup", "heart"],
            [
                "Relationships can be the most beautiful and the hardest parts of life 💕. I'm here for you.",
                "Your heart matters 💙. Share what's going on — I'm listening.",
                "Love can be complicated. You deserve kindness and understanding — from yourself too 🌸."
            ]
        ),
        (
            ["thank", "thanks", "appreciate", "grateful", "helpful"],
            [
                "You're so welcome! 😊 I'm always here whenever you need me.",
                "That really means a lot! 🌟 I'm rooting for you every step of the way.",
                "Happy to help! 🤗 Remember — you're doing great!"
            ]
        )
    ]

    // MARK: - Greetings

    private let greetingReplies = [
        "Hey there! 👋 Great to see you. How are you feeling today?",
        "Hi! 😊 I'm here for you. What's on your mind?",
        "Hello! 🌟 How's your day going so far?",
        "Hey! 🤗 So good to see you here. What would you like to talk about?"
    ]

    private init() {}

    // MARK: - Core

    func buildReply(for input: String) -> String {
        let normalized = input.lowercased()

        // Greeting check
        let greetingWords = ["hello", "hi", "hey", "good morning", "good afternoon", "good evening", "hola", "what's up", "howdy"]
        if greetingWords.contains(where: { normalized.contains($0) }) {
            return greetingReplies.randomElement()!
        }

        // Keyword matching
        for rule in keywordReplies {
            if rule.keywords.contains(where: { normalized.contains($0) }) {
                return rule.replies.randomElement()!
            }
        }

        // Fallback
        return motivationalReplies.randomElement()!
    }
}
