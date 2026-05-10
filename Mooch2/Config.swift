import SwiftUI
import UIKit

// MARK: - Adaptive Color System

extension Color {
    static let moochBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.075, green: 0.075, blue: 0.063, alpha: 1)
            : UIColor(red: 0.980, green: 0.980, blue: 0.969, alpha: 1)
    })
    static let moochSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.118, green: 0.118, blue: 0.106, alpha: 1)
            : UIColor.white
    })
    static let moochSurfaceSecond = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.145, green: 0.145, blue: 0.125, alpha: 1)
            : UIColor(red: 0.953, green: 0.941, blue: 0.910, alpha: 1)
    })
    static let moochBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.188, green: 0.188, blue: 0.157, alpha: 1)
            : UIColor(red: 0.898, green: 0.878, blue: 0.835, alpha: 1)
    })
    static let moochGreen = Color(red: 0.176, green: 0.416, blue: 0.184)
    static let moochGreenLight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.102, green: 0.180, blue: 0.102, alpha: 1)
            : UIColor(red: 0.910, green: 0.961, blue: 0.914, alpha: 1)
    })
    static let moochAmber = Color(red: 0.784, green: 0.412, blue: 0.039)
    static let moochAmberLight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.165, green: 0.102, blue: 0.031, alpha: 1)
            : UIColor(red: 0.996, green: 0.953, blue: 0.886, alpha: 1)
    })
    static let moochRed = Color(red: 0.753, green: 0.224, blue: 0.169)
    static let moochRedLight = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.165, green: 0.039, blue: 0.031, alpha: 1)
            : UIColor(red: 0.992, green: 0.929, blue: 0.918, alpha: 1)
    })
    static let moochTextPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.941, green: 0.937, blue: 0.910, alpha: 1)
            : UIColor(red: 0.102, green: 0.102, blue: 0.094, alpha: 1)
    })
    static let moochTextSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.604, green: 0.596, blue: 0.565, alpha: 1)
            : UIColor(red: 0.420, green: 0.408, blue: 0.376, alpha: 1)
    })
    static let moochTextTertiary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.420, green: 0.408, blue: 0.376, alpha: 1)
            : UIColor(red: 0.627, green: 0.616, blue: 0.596, alpha: 1)
    })

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Glass Card

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(Color.moochSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.moochBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func glassCard(_ cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Haptic

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

// MARK: - LiveBadge

struct LiveBadge: View {
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.moochGreen)
                .frame(width: 6, height: 6)
                .scaleEffect(pulsing ? 1.4 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulsing)
                .onAppear { pulsing = true }
            Text("LIVE")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.moochGreen)
                .tracking(1.5)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.moochGreenLight)
        .clipShape(Capsule())
    }
}

// MARK: - AnimatedNumber

struct AnimatedNumber: View {
    let value: Int
    let font: Font
    let color: Color
    @State private var displayed: Double = 0

    init(_ value: Int,
         font: Font = .system(size: 24, weight: .bold, design: .monospaced),
         color: Color = .primary) {
        self.value = value
        self.font = font
        self.color = color
    }

    var body: some View {
        Text("\(Int(displayed))")
            .font(font)
            .foregroundColor(color)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    displayed = Double(value)
                }
            }
            .onChange(of: value) { _, newVal in
                withAnimation(.easeOut(duration: 0.8)) {
                    displayed = Double(newVal)
                }
            }
    }
}
