import SwiftUI

struct CropComparisonView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private let crops: [CropType] = [.grapes, .lettuce, .walnuts, .almonds, .tomatoes]
    private static let harvestNowCrops: Set<CropType> = [.strawberries, .grapes, .lettuce, .cherries]
    private static let within48Crops: Set<CropType>   = [.almonds, .walnuts, .tomatoes, .apricots, .peaches]

    private var currentAQI: Int { appState.aqiData.value }

    var body: some View {
        ZStack(alignment: .top) {
            Color.moochBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    contextCard
                    cropTable
                }
                .padding(20)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.moochTextPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.moochSurface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.moochBorder, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("CROP COMPARISON")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color.moochTextPrimary)
                    .tracking(2.0)
                Text("Same fire · Same AQI · Different outcomes")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.moochTextSecondary)
            }
            Spacer()
        }
    }

    // MARK: Context Card

    private var contextCard: some View {
        HStack(spacing: 0) {
            contextStat(label: "EVENT", value: "CAMP FIRE")
            Divider().padding(.vertical, 10)
            contextStat(label: "AQI NOW", value: "\(currentAQI)", color: .moochRed)
            Divider().padding(.vertical, 10)
            contextStat(label: "WIND", value: "\(appState.weatherData.windSpeed) MPH \(appState.weatherData.windDirection)")
            Divider().padding(.vertical, 10)
            let dist = appState.nearestFireDistance.map { String(format: "%.1fMI", $0) } ?? "—"
            contextStat(label: "FIRE", value: "\(dist) \(appState.nearestFireBearing)", color: .moochRed)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard(12)
    }

    private func contextStat(label: String, value: String, color: Color = .moochTextPrimary) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.moochTextTertiary)
                .tracking(1.5)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Crop Table

    private var cropTable: some View {
        VStack(spacing: 0) {
            columnHeaders
            Divider().background(Color.moochBorder)
            ForEach(Array(crops.enumerated()), id: \.offset) { idx, crop in
                cropRow(crop)
                if idx < crops.count - 1 {
                    Divider().background(Color.moochBorder)
                }
            }
        }
        .glassCard(12)
    }

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            Text("CROP")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 14)
            Text("SAFE BELOW")
                .frame(width: 74, alignment: .center)
            Text("EXPOSURE")
                .frame(width: 74, alignment: .center)
            Text("VERDICT")
                .frame(width: 90, alignment: .center)
                .padding(.trailing, 8)
        }
        .font(.system(size: 8, weight: .semibold, design: .monospaced))
        .foregroundColor(Color.moochTextTertiary)
        .tracking(0.8)
        .padding(.vertical, 8)
    }

    private func cropRow(_ crop: CropType) -> some View {
        let info = crop.info
        let over = currentAQI > info.smokeAQIThreshold
        let ratio = Double(currentAQI) / Double(info.smokeAQIThreshold)
        let (statusText, statusBg, statusFg) = verdictStyle(crop: crop, over: over)

        return HStack(spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(info.color.opacity(0.15))
                        .frame(width: 30, height: 30)
                    Image(systemName: info.sfSymbol)
                        .font(.system(size: 13))
                        .foregroundColor(info.color)
                }
                Text(info.name)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.moochTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)

            Text("AQI \(info.smokeAQIThreshold)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.moochTextSecondary)
                .frame(width: 74, alignment: .center)

            Text(over ? String(format: "%.1f×", ratio) : "CLEAR")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(over ? .moochRed : .moochGreen)
                .frame(width: 74, alignment: .center)

            Text(statusText)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(statusFg)
                .tracking(0.5)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(statusBg)
                .clipShape(Capsule())
                .frame(width: 90, alignment: .center)
                .padding(.trailing, 8)
        }
        .padding(.vertical, 10)
    }

    private func verdictStyle(crop: CropType, over: Bool) -> (String, Color, Color) {
        if !over {
            return ("MONITOR", Color.moochGreenLight, Color.moochGreen)
        } else if Self.harvestNowCrops.contains(crop) {
            return ("HARVEST NOW", Color.moochRedLight, Color.moochRed)
        } else if Self.within48Crops.contains(crop) {
            return ("ACT < 48H", Color.moochAmberLight, Color.moochAmber)
        } else {
            return ("AT RISK", Color.moochAmberLight, Color.moochAmber)
        }
    }
}

#Preview {
    let state = AppState()
    state.loadDemoData()
    return CropComparisonView().environment(state)
}
