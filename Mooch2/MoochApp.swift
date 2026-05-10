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

    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var dotsOpacity: Double = 0
    @State private var activeDot = 0

    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(red: 0.980, green: 0.980, blue: 0.969).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Brand mark — cow logo raw on cream, no container
                Image("MoochLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .shadow(color: Color.moochGreen.opacity(0.15), radius: 16, x: 0, y: 6)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // Wordmark
                Text("Mooch")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.094))
                    .tracking(-0.5)
                    .padding(.top, 20)
                    .opacity(wordmarkOpacity)

                // Subtitle
                Text("FIELD INTELLIGENCE")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 0.627, green: 0.616, blue: 0.596))
                    .tracking(3.0)
                    .padding(.top, 8)
                    .opacity(subtitleOpacity)

                Spacer()

                // Loading dots
                HStack(spacing: 7) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(activeDot == i ? Color.moochGreen : Color(red: 0.878, green: 0.859, blue: 0.820))
                            .frame(width: 5, height: 5)
                            .animation(.easeInOut(duration: 0.2), value: activeDot)
                    }
                }
                .padding(.bottom, 20)
                .opacity(dotsOpacity)

                // Perspective field rows — bottom accent
                SplashFieldRows()
                    .frame(height: 108)
                    .opacity(dotsOpacity)
            }
        }
        .onAppear { startAnimations() }
        .onReceive(timer) { _ in
            activeDot = (activeDot + 1) % 3
        }
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.35)) {
            wordmarkOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.55)) {
            subtitleOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.75)) {
            dotsOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            onComplete()
        }
    }

    static let demoFarmName = "Paradise Farm"
}

// MARK: - Splash Field Rows

struct SplashFieldRows: View {
    @State private var glimmer = false

    private let green = Color(red: 0.176, green: 0.416, blue: 0.184)

    var body: some View {
        Canvas { ctx, size in
            let bands = 12
            let midX  = size.width * 0.5
            let horizon = size.height * 0.08

            for i in 0..<bands {
                let t0 = CGFloat(i)       / CGFloat(bands)
                let t1 = CGFloat(i + 1)   / CGFloat(bands)

                let y0 = horizon + (size.height - horizon) * t0
                let y1 = horizon + (size.height - horizon) * t1

                // Perspective spread — grows toward the viewer (bottom)
                let s0 = size.width * 0.72 * pow(t0, 0.6)
                let s1 = size.width * 0.72 * pow(t1, 0.6)

                let alpha: CGFloat = i % 2 == 0 ? 0.09 : 0.03

                var band = Path()
                band.move(to: CGPoint(x: midX - s0, y: y0))
                band.addLine(to: CGPoint(x: midX + s0, y: y0))
                band.addLine(to: CGPoint(x: midX + s1, y: y1))
                band.addLine(to: CGPoint(x: midX - s1, y: y1))
                band.closeSubpath()

                ctx.fill(band, with: .color(Color(red: 0.176, green: 0.416, blue: 0.184).opacity(alpha)))
            }
        }
        // Fade out near the horizon so bands emerge from nothing
        .mask(
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
        )
        // Gentle whole-view shimmer — slow breath
        .opacity(glimmer ? 1.0 : 0.55)
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: glimmer)
        .onAppear { glimmer = true }
    }
}
