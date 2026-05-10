import SwiftUI

struct CropRiskDashboard: View {
    let farm: FarmProfile
    let aqi: AQIData
    let fireActive: Bool
    let nearestFireDistance: Double?
    let nearestFireBearing: String

    private var cropInfo: CropInfo { farm.cropType.info }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            section1CropHeader
            Divider().background(Color.moochBorder).padding(.vertical, 10)
            section2DataColumns
            Divider().background(Color.moochBorder).padding(.vertical, 10)
            section3SmokeThreat
            if fireActive {
                Divider().background(Color.moochBorder).padding(.vertical, 10)
                section4WaterSource
            }
            Divider().background(Color.moochBorder).padding(.vertical, 10)
            section5UrgencyBar
        }
        .padding(14)
        .glassCard(12)
    }

    // MARK: Section 1 — Crop Header

    private var section1CropHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(cropInfo.color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: cropInfo.sfSymbol)
                    .font(.system(size: 17))
                    .foregroundColor(cropInfo.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(cropInfo.name.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.moochTextPrimary)
                    .tracking(1.0)
                sensitivityPill
            }
            Spacer()
            harvestUrgencyBadge
        }
    }

    private var sensitivityPill: some View {
        Text(cropInfo.smokeSensitivity.rawValue.uppercased())
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(cropInfo.smokeSensitivity.color)
            .tracking(1.0)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(cropInfo.smokeSensitivity.color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var harvestUrgencyBadge: some View {
        let over = aqi.value > cropInfo.smokeAQIThreshold
        let urgent = over && cropInfo.harvestWindowHours <= 24
        let text: String
        let bg: Color
        let fg: Color
        if over && urgent {
            text = "ACT IN \(cropInfo.harvestWindowHours)H"
            bg = Color.moochRedLight; fg = Color.moochRed
        } else if over {
            text = "WITHIN \(cropInfo.harvestWindowHours)H"
            bg = Color.moochAmberLight; fg = Color.moochAmber
        } else {
            text = "WINDOW OK"
            bg = Color.moochGreenLight; fg = Color.moochGreen
        }
        return Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(fg)
            .tracking(0.8)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }

    // MARK: Section 2 — Data Columns

    private var section2DataColumns: some View {
        HStack {
            dataColumn(label: "SAFE BELOW", value: "AQI \(cropInfo.smokeAQIThreshold)",
                       valueColor: Color.moochTextSecondary)
            Spacer()
            dataColumn(label: "AQI NOW",
                       value: "\(aqi.value)",
                       valueColor: aqi.value > cropInfo.smokeAQIThreshold ? .moochRed : .moochGreen)
            Spacer()
            let over = aqi.value > cropInfo.smokeAQIThreshold
            let ratio = Double(aqi.value) / Double(cropInfo.smokeAQIThreshold)
            dataColumn(label: "EXPOSURE",
                       value: over ? String(format: "%.1f×", ratio) : "CLEAR",
                       valueColor: over ? .moochRed : .moochGreen)
        }
    }

    private func dataColumn(label: String, value: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(Color.moochTextTertiary)
                .tracking(1.0)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
        }
    }

    // MARK: Section 3 — Smoke Threat Row

    private var section3SmokeThreat: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                let pct = min(Double(aqi.value) / 300.0, 1.0)
                let (r, g, b) = aqi.ringColor
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.moochSurfaceSecond)
                        .frame(height: 6)
                    Capsule()
                        .fill(Color(red: r, green: g, blue: b))
                        .frame(width: geo.size.width * pct, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(aqi.shortCategory) · \(cropInfo.seasonNote)")
                .font(.system(size: 10, design: .default))
                .foregroundColor(Color.moochTextSecondary)
                .lineLimit(2)
        }
    }

    // MARK: Section 4 — Water Source

    private var section4WaterSource: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: waterIcon)
                    .font(.system(size: 14))
                    .foregroundColor(waterColor)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(farm.waterSource.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(waterColor)
                        .tracking(1.0)
                    Text(farm.waterSource.fireNote)
                        .font(.system(size: 10))
                        .foregroundColor(Color.moochTextSecondary)
                }
            }
            Text(fireProximityNote)
                .font(.system(size: 10))
                .foregroundColor(Color.moochTextSecondary)
                .padding(.leading, 28)
        }
    }

    private var waterIcon: String {
        switch farm.waterSource {
        case .well:      return "drop.fill"
        case .canal:     return "water.waves"
        case .reservoir: return "lake"
        }
    }

    private var waterColor: Color {
        switch farm.waterSource {
        case .well:                return .moochGreen
        case .canal, .reservoir:   return .moochAmber
        }
    }

    private var fireProximityNote: String {
        let distStr = nearestFireDistance.map { String(format: "%.1f", $0) } ?? "?"
        let bearing = nearestFireBearing
        switch farm.waterSource {
        case .well:
            return "Well unaffected by fire proximity"
        case .canal:
            return "Canal intake risk: fire \(distStr) mi \(bearing) upstream"
        case .reservoir:
            return "Confirm reservoir inlet depth — surface may be compromised"
        }
    }

    // MARK: Section 5 — Urgency Bar

    private var section5UrgencyBar: some View {
        let (text, bg, fg) = urgencyStyle
        return HStack {
            Spacer()
            Text(text)
                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                .foregroundColor(fg)
                .tracking(2.0)
            Spacer()
        }
        .padding(.vertical, 10)
        .background(bg)
        .clipShape(Capsule())
    }

    private var urgencyStyle: (String, Color, Color) {
        let over = aqi.value > cropInfo.smokeAQIThreshold
        let harvestNowCrops: Set<CropType> = [.strawberries, .grapes, .lettuce, .cherries]
        let within48Crops: Set<CropType>   = [.almonds, .walnuts, .tomatoes, .apricots, .peaches]

        if over && harvestNowCrops.contains(farm.cropType) {
            return ("HARVEST NOW", Color.moochRed, Color.white)
        } else if over && within48Crops.contains(farm.cropType) {
            return ("WITHIN 48 HRS", Color.moochAmber, Color.white)
        } else {
            return ("MONITOR", Color.moochGreenLight, Color.moochGreen)
        }
    }
}

#Preview {
    let farm = FarmProfile(name: "Paradise Farm", latitude: 39.76, longitude: -121.62,
                           cropType: .walnuts, waterSource: .canal, acreage: 120)
    let aqi = AQIData(value: 284, category: "Very Unhealthy", parameter: "PM2.5")
    CropRiskDashboard(farm: farm, aqi: aqi, fireActive: true,
                      nearestFireDistance: 8.2, nearestFireBearing: "NE")
        .padding()
        .background(Color.moochBackground)
}
