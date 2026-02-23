import SwiftUI

struct OnboardingFlowView: View {
    let onConfigureProfile: () -> Void
    let onFinishWithoutProfile: () -> Void

    @State private var stepIndex = 0
    @State private var animateBackground = false

    private let steps: [OnboardingStep] = [
        OnboardingStep(
            title: "Welcome! 👋",
            subtitle: "ChatPrototipo is your personal support chat. I'm here to listen and motivate you every day.",
            icon: "sparkles",
            accent: [.indigo, .blue],
            symbolEffect: "sparkles"
        ),
        OnboardingStep(
            title: "Make it yours ✨",
            subtitle: "Set your name and a photo so every conversation feels personal and welcoming.",
            icon: "person.crop.circle.badge.plus",
            accent: [.teal, .cyan],
            symbolEffect: "person.crop.circle.badge.plus"
        ),
        OnboardingStep(
            title: "Chat naturally 💬",
            subtitle: "Just type how you feel. I react to your words and always cheer you on with kind replies.",
            icon: "message.fill",
            accent: [.purple, .indigo],
            symbolEffect: "message.fill"
        )
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: steps[stepIndex].accent.map { $0.opacity(0.18) } + [Color(.systemBackground)],
                startPoint: animateBackground ? .topLeading : .bottomTrailing,
                endPoint: animateBackground ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateBackground)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { i in
                            Capsule()
                                .fill(i == stepIndex ? steps[stepIndex].accent[0] : Color(.systemGray4))
                                .frame(width: i == stepIndex ? 22 : 7, height: 7)
                                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: stepIndex)
                        }
                    }
                    Spacer()
                    Button("Skip") {
                        onFinishWithoutProfile()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Card area (TabView for swipe)
                TabView(selection: $stepIndex) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        OnboardingCardView(step: step, isActive: stepIndex == index)
                            .tag(index)
                            .padding(.horizontal, 20)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Action buttons
                VStack(spacing: 12) {
                    if stepIndex == steps.count - 1 {
                        Button(action: onConfigureProfile) {
                            Label("Set Up My Profile", systemImage: "person.crop.circle.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: steps[stepIndex].accent,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: steps[stepIndex].accent[0].opacity(0.4), radius: 10, x: 0, y: 5)
                        }

                        Button("Start Without Profile") {
                            onFinishWithoutProfile()
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                    } else {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                stepIndex += 1
                            }
                        }) {
                            HStack {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: steps[stepIndex].accent,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: steps[stepIndex].accent[0].opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: stepIndex)
            }
        }
        .onAppear { animateBackground = true }
    }
}

// MARK: - OnboardingStep

private struct OnboardingStep {
    let title: String
    let subtitle: String
    let icon: String
    let accent: [Color]
    let symbolEffect: String
}

// MARK: - OnboardingCardView

private struct OnboardingCardView: View {
    let step: OnboardingStep
    let isActive: Bool

    @State private var iconBounce = false
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon with glow
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(step.accent[0].opacity(glowPulse ? 0.18 : 0.08))
                    .frame(width: 140, height: 140)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                // Mid ring
                Circle()
                    .fill(step.accent[0].opacity(glowPulse ? 0.12 : 0.05))
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.3), value: glowPulse)

                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: step.accent,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: step.accent[0].opacity(0.5), radius: glowPulse ? 20 : 12, x: 0, y: 8)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowPulse)

                Image(systemName: step.icon)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(iconBounce ? 1.08 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true).delay(0.5), value: iconBounce)
            }

            // Text block
            VStack(spacing: 14) {
                Text(step.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(step.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }

            Spacer()
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 10)
        )
        .scaleEffect(isActive ? 1.0 : 0.95)
        .opacity(isActive ? 1.0 : 0.7)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isActive)
        .onAppear {
            if isActive {
                iconBounce = true
                glowPulse = true
            }
        }
        .onChange(of: isActive) { _, active in
            iconBounce = active
            glowPulse = active
        }
    }
}
