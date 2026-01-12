//
//  OnboardingPageView.swift
//  Textory
//
//  Created with Claude Code
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var floatingOffset: CGFloat = 0
    @State private var bubbleOffsets: [CGFloat] = [50, 50, 50]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated illustration area
            ZStack {
                // Floating background circles
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .offset(y: floatingOffset)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .offset(y: -floatingOffset * 0.7)

                // Main icon with glow
                ZStack {
                    // Glow effect
                    Image(systemName: page.iconName)
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .blur(radius: 20)
                        .scaleEffect(iconScale * 1.2)

                    // Main icon
                    Image(systemName: page.iconName)
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(Color.white)
                        .scaleEffect(iconScale)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }

                // Decorative chat bubbles for first page
                if page.iconName == "bubble.left.and.bubble.right.fill" {
                    chatBubblesDecoration
                }

                // Sparkle particles for AI page
                if page.iconName == "sparkles" {
                    sparkleParticles
                }

                // Play icons for export page
                if page.iconName == "play.rectangle.fill" {
                    socialMediaIcons
                }

                // Hearts for final page
                if page.iconName == "heart.fill" {
                    floatingHearts
                }
            }
            .frame(height: 300)

            Spacer()

            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            .opacity(textOpacity)

            Spacer()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animateIn()
            } else {
                resetAnimations()
            }
        }
        .onAppear {
            if isActive {
                animateIn()
            }
        }
    }

    // MARK: - Decorative Elements

    private var chatBubblesDecoration: some View {
        Group {
            // Left bubble
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.25))
                .frame(width: 80, height: 40)
                .offset(x: -100, y: -60 + bubbleOffsets[0])
                .opacity(bubbleOffsets[0] < 50 ? 1 : 0)

            // Right bubble
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.2))
                .frame(width: 100, height: 35)
                .offset(x: 90, y: 20 + bubbleOffsets[1])
                .opacity(bubbleOffsets[1] < 50 ? 1 : 0)

            // Bottom bubble
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.15))
                .frame(width: 70, height: 32)
                .offset(x: -70, y: 80 + bubbleOffsets[2])
                .opacity(bubbleOffsets[2] < 50 ? 1 : 0)
        }
    }

    private var sparkleParticles: some View {
        Group {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: [16, 12, 20, 14, 18][index]))
                    .foregroundColor(.white.opacity(0.6))
                    .offset(
                        x: CGFloat([-80, 90, -60, 100, -30][index]),
                        y: CGFloat([-70, -40, 60, 30, -90][index]) + floatingOffset * CGFloat([0.5, -0.3, 0.7, -0.5, 0.4][index])
                    )
                    .opacity(iconOpacity)
            }
        }
    }

    private var socialMediaIcons: some View {
        HStack(spacing: 40) {
            ForEach(["video.fill", "camera.fill", "play.tv.fill"], id: \.self) { icon in
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
            }
        }
        .offset(y: 120)
        .opacity(textOpacity)
    }

    private var floatingHearts: some View {
        Group {
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: [24, 18, 28, 20][index]))
                    .foregroundColor(.white.opacity([0.4, 0.3, 0.5, 0.35][index]))
                    .offset(
                        x: CGFloat([-90, 80, -50, 100][index]),
                        y: CGFloat([-50, 40, 70, -80][index]) + floatingOffset * CGFloat([0.6, -0.4, 0.5, -0.6][index])
                    )
                    .opacity(iconOpacity)
            }
        }
    }

    // MARK: - Animations

    private func animateIn() {
        // Reset first
        iconScale = 0.5
        iconOpacity = 0
        textOpacity = 0
        bubbleOffsets = [50, 50, 50]

        // Icon animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1
        }

        // Text animation
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1
        }

        // Bubble animations (staggered)
        for i in 0..<3 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4 + Double(i) * 0.1)) {
                bubbleOffsets[i] = 0
            }
        }

        // Continuous floating animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            floatingOffset = 10
        }
    }

    private func resetAnimations() {
        iconScale = 0.5
        iconOpacity = 0
        textOpacity = 0
        floatingOffset = 0
        bubbleOffsets = [50, 50, 50]
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "Create Chat Stories",
            subtitle: "Design fake text conversations that look completely real. Perfect for storytelling and content creation.",
            iconName: "bubble.left.and.bubble.right.fill",
            gradientColors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
            accentColor: .white
        ),
        isActive: true
    )
    .background(
        LinearGradient(
            colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
