import SwiftUI
import MapKit

// MARK: - Live Map View

struct LiveMapView: View {
    @Environment(AppState.self) private var appState
    @State private var drawerExpanded = false
    @State private var showActionPlan = false
    @State private var showFarmList = false
    @State private var showCropComparison = false

    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen map
            MoochMapView(
                farms: appState.activeFarm.map { [$0] } ?? [],
                hotspots: appState.hotspots,
                windDirection: appState.weatherData.windDirection,
                aqiValue: appState.aqiData.value,
                isSetupMode: false,
                onTap: nil
            )
            .ignoresSafeArea()

            // Scanline overlay (decorative, non-interactive)
            ScanlineOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Top HUD
            VStack(spacing: 0) {
                topHUD
                if appState.fireAlertActive {
                    fireAlertBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if appState.isLoadingData {
                    loadingPill
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 0)
        }
        .overlay(alignment: .bottom) {
            FieldBriefDrawer(
                expanded: $drawerExpanded,
                showActionPlan: $showActionPlan,
                showFarmList: $showFarmList,
                showCropComparison: $showCropComparison
            )
            .padding(.horizontal, 14)
        }
        .fullScreenCover(isPresented: $showActionPlan) {
            ActionPlanView()
        }
        .fullScreenCover(isPresented: $showCropComparison) {
            CropComparisonView()
        }
        .sheet(isPresented: $showFarmList) {
            FarmListView()
                .presentationDetents([.medium, .large])
        }
        .task(id: appState.activeFarmID) {
            await appState.fetchAllData()
        }
        .animation(.easeInOut(duration: 0.3), value: appState.fireAlertActive)
        .animation(.easeInOut(duration: 0.3), value: appState.isLoadingData)
    }

    // MARK: Demo Ribbon

    private var demoRibbon: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundColor(Color.moochAmber)
            Text("DEMO — Historical Camp Fire data · Nov 8 2018 · AQI 284 · Wind NE 35 mph")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.moochAmber)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color.moochAmberLight)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.moochAmber.opacity(0.3)), alignment: .bottom)
        .padding(.horizontal, -14)
    }

    private var dynamicIslandClearance: CGFloat {
        let inset = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 54
        return inset - 8
    }

    // MARK: Top HUD

    private var topHUD: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    MoochLogoPill()
                    LiveBadge()
                }
                WindCompassWidget(
                    windSpeed: appState.weatherData.windSpeed,
                    windDirection: appState.weatherData.windDirection
                )
            }
            Spacer()
            AQIWidget(aqi: appState.aqiData)
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    // MARK: Fire Alert Banner

    private var fireAlertBanner: some View {
        let dist = appState.nearestFireDistance ?? 0
        let bearing = appState.nearestFireBearing
        let urgent = dist < 15
        let text = urgent
            ? String(format: "ACT NOW — FIRE %.1f MI %@", dist, bearing)
            : String(format: "FIRE DETECTED %.1f MI %@", dist, bearing)

        return Text(text)
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .foregroundColor(.white)
            .tracking(1.5)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(urgent ? Color.moochRed : Color.moochAmber)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
            .scaleEffect(urgent ? 1.0 : 1.0)
            .animation(
                urgent ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                value: urgent
            )
            .padding(.top, 6)
    }

    // MARK: Loading Pill

    private var loadingPill: some View {
        HStack(spacing: 8) {
            ProgressView().tint(.white).scaleEffect(0.8)
            Text("LOADING FIELD DATA…")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .tracking(1.0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.65))
        .clipShape(Capsule())
        .padding(.top, 6)
    }
}

// MARK: - Scanline Overlay

private struct ScanlineOverlay: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 4
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                         with: .color(.black.opacity(0.03)))
                y += spacing
            }
        }
    }
}

// MARK: - AQI Widget

struct AQIWidget: View {
    let aqi: AQIData
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(Color.moochBorder, lineWidth: 5)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: appeared ? CGFloat(aqi.value) / 500.0 : 0)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 60, height: 60)
                    .animation(.easeOut(duration: 1.2), value: appeared)
                AnimatedNumber(aqi.value,
                               font: .system(size: 16, weight: .black, design: .monospaced),
                               color: ringColor)
            }
            Text(aqi.shortCategory)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(ringColor)
                .tracking(1.0)
        }
        .padding(10)
        .glassCard(14)
        .onAppear { appeared = true }
    }

    private var ringColor: Color {
        let (r, g, b) = aqi.ringColor
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Wind Compass Widget

struct WindCompassWidget: View {
    let windSpeed: Int
    let windDirection: String

    private var bearingDegrees: Double {
        let map: [String: Double] = [
            "N": 0, "NNE": 22.5, "NE": 45, "ENE": 67.5,
            "E": 90, "ESE": 112.5, "SE": 135, "SSE": 157.5,
            "S": 180, "SSW": 202.5, "SW": 225, "WSW": 247.5,
            "W": 270, "WNW": 292.5, "NW": 315, "NNW": 337.5
        ]
        return map[windDirection] ?? 0
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.moochBorder, lineWidth: 1)
                    .frame(width: 50, height: 50)

                // Cardinal labels
                ForEach(["N","E","S","W"].indices, id: \.self) { i in
                    let dirs = ["N","E","S","W"]
                    let angle = Double(i) * 90.0
                    Text(dirs[i])
                        .font(.system(size: 7, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.moochTextTertiary)
                        .offset(compassOffset(degrees: angle, radius: 19))
                }

                // Wind arrow
                WindArrow()
                    .fill(Color.moochRed)
                    .frame(width: 14, height: 24)
                    .rotationEffect(.degrees(bearingDegrees))
            }

            Text("\(windSpeed) MPH")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Color.moochTextSecondary)
                .tracking(0.5)
        }
        .padding(8)
        .glassCard(12)
    }

    private func compassOffset(degrees: Double, radius: CGFloat) -> CGSize {
        let rad = (degrees - 90) * .pi / 180
        return CGSize(width: Foundation.cos(rad) * radius, height: Foundation.sin(rad) * radius)
    }
}

// MARK: - Wind Arrow Shape

struct WindArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX
        let top = rect.minY
        let bot = rect.maxY
        let w = rect.width
        path.move(to: CGPoint(x: mid, y: top))
        path.addLine(to: CGPoint(x: mid + w * 0.3, y: top + rect.height * 0.35))
        path.addLine(to: CGPoint(x: mid + w * 0.1, y: top + rect.height * 0.35))
        path.addLine(to: CGPoint(x: mid + w * 0.1, y: bot))
        path.addLine(to: CGPoint(x: mid - w * 0.1, y: bot))
        path.addLine(to: CGPoint(x: mid - w * 0.1, y: top + rect.height * 0.35))
        path.addLine(to: CGPoint(x: mid - w * 0.3, y: top + rect.height * 0.35))
        path.closeSubpath()
        return path
    }
}

// MARK: - AQI Forecast Bar

struct AQIForecastBar: View {
    let baseAQI: Int

    private var forecasts: [(hour: Int, value: Int)] {
        let multipliers = [1.0, 1.08, 1.14, 1.09, 1.04, 0.98]
        return multipliers.enumerated().map { (idx, m) in
            (hour: idx, value: Int(Double(baseAQI) * m))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("6-HOUR AQI FORECAST")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color.moochTextTertiary)
                .tracking(2.0)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(forecasts, id: \.hour) { item in
                    forecastBar(item)
                }
            }
        }
        .padding(14)
        .glassCard(12)
    }

    private func forecastBar(_ item: (hour: Int, value: Int)) -> some View {
        let maxVal: CGFloat = 400
        let height = max(24, min(80, CGFloat(item.value) / maxVal * 80))
        let (r, g, b) = AQIData(value: item.value, category: "", parameter: "").ringColor

        return VStack(spacing: 4) {
            Text("\(item.value)")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(red: r, green: g, blue: b))
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(red: r, green: g, blue: b).opacity(0.8))
                .frame(height: height)
            Text(item.hour == 0 ? "NOW" : "+\(item.hour)H")
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(Color.moochTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Field Brief Drawer

struct FieldBriefDrawer: View {
    @Environment(AppState.self) private var appState
    @Binding var expanded: Bool
    @Binding var showActionPlan: Bool
    @Binding var showFarmList: Bool
    @Binding var showCropComparison: Bool

    private var statusColor: Color {
        if appState.fireAlertActive { return .moochRed }
        if appState.aqiData.value > 100 { return .moochAmber }
        return .moochGreen
    }

    private var statusLine: String {
        if appState.fireAlertActive, let dist = appState.nearestFireDistance {
            return String(format: "FIRE %.1f MI %@", dist, appState.nearestFireBearing)
        }
        return "AQI \(appState.aqiData.value) · \(appState.aqiData.shortCategory)"
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
            peekContent
            if expanded {
                expandedContent
            }
        }
        .background(Color.moochBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .offset(y: 22))
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: -6)
        .gesture(
            DragGesture()
                .onEnded { val in
                    if val.translation.height < -30 { withAnimation(.spring(response: 0.35)) { expanded = true } }
                    if val.translation.height > 30  { withAnimation(.spring(response: 0.35)) { expanded = false } }
                }
        )
    }

    // MARK: Drag Handle

    private var dragHandle: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.moochBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .onTapGesture {
                    withAnimation(.spring(response: 0.35)) { expanded.toggle() }
                }
        }
    }

    // MARK: Peek Content

    private var peekContent: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 11) {
                Text(appState.activeFarm?.name ?? "No Farm Selected")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.moochTextPrimary)
                    .lineLimit(1)
                HStack(spacing: 7) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusLine)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(statusColor)
                        .tracking(0.3)
                }
                peekChips
            }
            Spacer()
            Button {
                haptic(.light)
                showFarmList = true
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.moochTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.moochSurface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.moochBorder, lineWidth: 1))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
    }

    private var peekChips: some View {
        HStack(spacing: 6) {
            if let farm = appState.activeFarm {
                let info = farm.cropType.info
                let aqi = appState.aqiData.value
                let over = aqi > info.smokeAQIThreshold

                // Crop chip
                peekChip(
                    label: "\(info.emoji) \(info.name.uppercased())",
                    fg: Color(info.color),
                    bg: Color(info.color).opacity(0.12)
                )

                // AQI chip
                let (aqiFg, aqiBg): (Color, Color) = over
                    ? (.moochRed, .moochRedLight)
                    : (.moochGreen, .moochGreenLight)
                peekChip(label: "AQI \(aqi)", fg: aqiFg, bg: aqiBg)

                // Urgency chip
                let (urgText, urgFg, urgBg) = peekUrgency(farm: farm, aqi: aqi)
                peekChip(label: urgText, fg: urgFg, bg: urgBg)
            }
        }
    }

    private func peekChip(label: String, fg: Color, bg: Color) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(fg)
            .tracking(0.5)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }

    private func peekUrgency(farm: FarmProfile, aqi: Int) -> (String, Color, Color) {
        let info = farm.cropType.info
        let over = aqi > info.smokeAQIThreshold
        let harvestNow: Set<CropType> = [.strawberries, .grapes, .lettuce, .cherries]
        let within48:   Set<CropType> = [.almonds, .walnuts, .tomatoes, .apricots, .peaches]
        if !over       { return ("MONITOR",      .moochGreen, .moochGreenLight) }
        if harvestNow.contains(farm.cropType) { return ("HARVEST NOW", .moochRed,   .moochRedLight)  }
        if within48.contains(farm.cropType)   { return ("ACT < 48H",   .moochAmber, .moochAmberLight) }
        return ("AT RISK", .moochAmber, .moochAmberLight)
    }

    // MARK: Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        Divider().background(Color.moochBorder)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusRows
                actionPlanButton
                cropComparisonButton
                AQIForecastBar(baseAQI: appState.aqiData.value)
                if let farm = appState.activeFarm {
                    CropRiskDashboard(
                        farm: farm,
                        aqi: appState.aqiData,
                        fireActive: appState.fireAlertActive,
                        nearestFireDistance: appState.nearestFireDistance,
                        nearestFireBearing: appState.nearestFireBearing
                    )
                }
                resetButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .frame(maxHeight: 500)
    }

    private var statusRows: some View {
        VStack(spacing: 0) {
            if let dist = appState.nearestFireDistance {
                StatusRow(
                    icon: "flame.fill",
                    label: String(format: "FIRE %.1f MI %@", dist, appState.nearestFireBearing),
                    color: appState.fireAlertActive ? .moochRed : .moochAmber
                )
                Divider().background(Color.moochBorder).padding(.vertical, 1)
            }
            StatusRow(
                icon: "wind",
                label: "\(appState.weatherData.windSpeed) MPH \(appState.weatherData.windDirection)",
                color: Color.moochTextSecondary
            )
            Divider().background(Color.moochBorder).padding(.vertical, 1)
            StatusRow(
                icon: "aqi.medium",
                label: "AQI \(appState.aqiData.value) — \(appState.aqiData.category)",
                color: Color(red: appState.aqiData.ringColor.0,
                             green: appState.aqiData.ringColor.1,
                             blue: appState.aqiData.ringColor.2)
            )
        }
        .padding(.vertical, 4)
        .glassCard(12)
    }

    private var actionPlanButton: some View {
        Button {
            haptic(.heavy)
            showActionPlan = true
            if appState.actionPlan.isEmpty {
                Task { await appState.generatePlan() }
            }
        } label: {
            HStack {
                Image(systemName: "bolt.fill")
                Text("GET ACTION PLAN")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(1.5)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(appState.fireAlertActive ? Color.moochRed : Color.moochGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var cropComparisonButton: some View {
        Button {
            haptic(.medium)
            showCropComparison = true
        } label: {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                Text("CROP COMPARISON")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(1.5)
            }
            .foregroundColor(Color.moochTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.moochSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.moochBorder, lineWidth: 1)
            )
        }
    }

    private var resetButton: some View {
        Button {
            haptic(.medium)
            appState.clearAllFarms()
        } label: {
            Text("Reset Farm Setup")
                .font(.system(size: 13))
                .foregroundColor(Color.moochTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 20, alignment: .center)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color.moochTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
