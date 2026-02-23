import SwiftUI

struct OnboardingFlowView: View {
    let onConfigureProfile: () -> Void
    let onFinishWithoutProfile: () -> Void

    @State private var stepIndex = 0

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome to ChatPrototipo",
            subtitle: "A local-first support chat that helps you stay focused and motivated.",
            icon: "sparkles",
            accent: [.blue, .cyan]
        ),
        OnboardingStep(
            title: "Make it yours",
            subtitle: "Set your display name and photo so the experience feels personal.",
            icon: "person.crop.circle.badge.plus",
            accent: [.teal, .mint]
        ),
        OnboardingStep(
            title: "Start chatting",
            subtitle: "Type naturally. The bot reacts to keywords and provides supportive responses.",
            icon: "message.fill",
            accent: [.indigo, .blue]
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemBackground), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Step \(stepIndex + 1) of \(steps.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Skip") {
                        onFinishWithoutProfile()
                    }
                    .buttonStyle(.plain)
                }

                TabView(selection: $stepIndex) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        OnboardingCard(step: step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                HStack(spacing: 12) {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepIndex = max(0, stepIndex - 1)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(stepIndex == 0)

                    if stepIndex < steps.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                stepIndex += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Set Up Profile") {
                            onConfigureProfile()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Start Now") {
                            onFinishWithoutProfile()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct OnboardingStep {
    let title: String
    let subtitle: String
    let icon: String
    let accent: [Color]
}

private struct OnboardingCard: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 18) {
            Circle()
                .fill(LinearGradient(colors: step.accent, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 92, height: 92)
                .overlay(
                    Image(systemName: step.icon)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                )

            Text(step.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text(step.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
        )
    }
}
