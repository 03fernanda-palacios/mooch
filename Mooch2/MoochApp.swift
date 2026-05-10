import SwiftUI
import Combine

@main
struct MoochApp: App {
    @State private var appState = AppState()
    @State private var splashDone = false

    var body: some Scene {
        WindowGroup {
            if splashDone {
                RootView()
                    .environment(appState)
            } else {
                SplashView(onComplete: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        splashDone = true
                    }
                })
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    let onComplete: () -> Void

    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var activeDot = 0

    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(red: 0.980, green: 0.980, blue: 0.969).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                MoochLogo(size: 72)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .padding(.bottom, 16)

                // Wordmark
                Text("Mooch")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.094))
                    .opacity(textOpacity)

                // Subtitle
                Text("FIELD INTELLIGENCE")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.420, green: 0.408, blue: 0.376))
                    .tracking(1.5)
                    .opacity(subtitleOpacity)
                    .padding(.top, 6)

                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(activeDot == i ? Color.moochGreen : Color(red: 0.898, green: 0.878, blue: 0.835))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: activeDot)
                    }
                }
                .padding(.top, 20)
                .opacity(textOpacity)

                Spacer()

                // Field row decoration
                FieldRowDecoration()
                    .frame(height: 80)
                    .opacity(textOpacity)
            }
        }
        .onAppear { startAnimations() }
        .onReceive(timer) { _ in
            activeDot = (activeDot + 1) % 3
        }
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            textOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            subtitleOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete()
        }
    }

    // Demo entry: "Paradise Farm" — Camp Fire, Butte County CA, used in loadDemoData()
    static let demoFarmName = "Paradise Farm"
}

// MARK: - Field Row Decoration

struct FieldRowDecoration: View {
    var body: some View {
        Canvas { ctx, size in
            let rowCount = 8
            let rowHeight = size.height / CGFloat(rowCount)
            let vanishX = size.width * 0.5

            for i in 0..<rowCount {
                let t = CGFloat(i) / CGFloat(rowCount)
                let y = rowHeight * CGFloat(i)
                let leftX   = vanishX - (size.width * 0.6 * (1 - t * 0.4))
                let rightX  = vanishX + (size.width * 0.6 * (1 - t * 0.4))
                let alpha   = 0.05 + 0.12 * (1 - t)
                let width   = max(1, 3 * (1 - t * 0.6))

                var path = Path()
                path.move(to: CGPoint(x: leftX, y: y))
                path.addLine(to: CGPoint(x: rightX, y: y))
                ctx.stroke(path, with: .color(.moochGreen.opacity(alpha)), lineWidth: width)
            }
        }
    }
}
