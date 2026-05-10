import SwiftUI
import MessageUI

// MARK: - Action Plan View

struct ActionPlanView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var checkedItems: Set<Int> = []
    @State private var factIndex = 0
    @State private var isShowingSMS = false
    @State private var appeared = false
    @State private var regenCount = 0

    private let loadingPhrases = [
        "Analyzing crop exposure data…",
        "Prioritizing crew assignments…",
        "Cross-referencing fire proximity…",
        "Calculating smoke taint risk…",
        "Optimizing harvest window…",
        "Assessing water source contamination…",
    ]

    private let regenLabels = ["RE-GENERATE", "REFINE PLAN", "NEW ANALYSIS"]

    var body: some View {
        ZStack(alignment: .top) {
            Color.moochBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    riskCard
                    planContent
                    bottomActions
                }
                .padding(20)
            }
        }
        .offset(y: appeared ? 0 : 30)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
            startFactCycle()
        }
        .sheet(isPresented: $isShowingSMS) {
            if let farm = appState.activeFarm {
                let dist = appState.nearestFireDistance ?? 0
                let text = APIService.notifyCrewText(
                    farm: farm,
                    aqi: appState.aqiData.value,
                    distance: dist,
                    bearing: appState.nearestFireBearing
                )
                SMSComposeView(body: text)
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
                Text("ACTION PLAN")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color.moochTextPrimary)
                    .tracking(2.0)
                if let farm = appState.activeFarm {
                    Text(farm.name)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color.moochTextSecondary)
                }
            }
            Spacer()
            LiveBadge()
        }
    }

    // MARK: Risk Card

    private var riskCard: some View {
        HStack(spacing: 0) {
            if let farm = appState.activeFarm {
                riskStat(label: "CROP",  value: farm.cropType.info.name.uppercased())
                Divider().padding(.vertical, 10)
                riskStat(label: "AQI",   value: "\(appState.aqiData.value)")
                Divider().padding(.vertical, 10)
                riskStat(label: "WATER", value: farm.waterSource.rawValue.uppercased())
                if let dist = appState.nearestFireDistance {
                    Divider().padding(.vertical, 10)
                    riskStat(label: "FIRE",
                             value: String(format: "%.1f MI %@", dist, appState.nearestFireBearing).uppercased(),
                             color: appState.fireAlertActive ? .moochRed : .moochAmber)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard(12)
    }

    private func riskStat(label: String, value: String, color: Color = .moochTextPrimary) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.moochTextTertiary)
                .tracking(1.5)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Plan Content

    @ViewBuilder
    private var planContent: some View {
        if appState.isLoadingPlan {
            loadingView
        } else if appState.actionPlan.isEmpty {
            emptyPlanView
        } else {
            checklistView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.moochGreen)
                .scaleEffect(1.2)
            Text(loadingPhrases[factIndex % loadingPhrases.count])
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color.moochTextSecondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.5), value: factIndex)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassCard()
    }

    private var emptyPlanView: some View {
        Button {
            haptic(.heavy)
            Task { await appState.generatePlan() }
        } label: {
            Label("GENERATE ACTION PLAN", systemImage: "bolt.fill")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .tracking(1.0)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.moochGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var checklistView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let items = parsePlanItems(appState.actionPlan)
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                checklistRow(index: idx, text: item)
                if idx < items.count - 1 {
                    Divider().background(Color.moochBorder)
                }
            }
        }
        .glassCard(12)
    }

    private func checklistRow(index: Int, text: String) -> some View {
        Button {
            haptic(.light)
            if checkedItems.contains(index) {
                checkedItems.remove(index)
            } else {
                checkedItems.insert(index)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(checkedItems.contains(index) ? Color.moochGreen : Color.moochBorder, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if checkedItems.contains(index) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.moochGreen)
                    }
                }
                .padding(.top, 2)

                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(checkedItems.contains(index)
                                     ? Color.moochTextTertiary : Color.moochTextPrimary)
                    .strikethrough(checkedItems.contains(index), color: Color.moochTextTertiary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private func parsePlanItems(_ plan: String) -> [String] {
        let lines = plan.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var items: [String] = []
        for line in lines {
            // "1. " / "12. " numbered lists
            if let match = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                let cleaned = String(line[match.upperBound...]).trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty { items.append(cleaned) }
            // "- " / "• " / "* " bullets
            } else if line.hasPrefix("- ") || line.hasPrefix("• ") || line.hasPrefix("* ") {
                let cleaned = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty { items.append(cleaned) }
            }
        }
        // Fallback: any substantive line
        if items.isEmpty {
            items = lines.filter { $0.count > 10 }
        }
        return Array(items.prefix(5))
    }

    // MARK: Bottom Actions

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                haptic(.heavy)
                isShowingSMS = true
            } label: {
                Label("NOTIFY CREW", systemImage: "message.fill")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(0.8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.moochGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                haptic(.medium)
                regenCount += 1
                checkedItems.removeAll()
                Task { await appState.generatePlan() }
            } label: {
                Label(regenLabels[regenCount % regenLabels.count], systemImage: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.moochTextSecondary)
                    .tracking(0.8)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(Color.moochSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.moochBorder, lineWidth: 1))
            }
        }
    }

    private func startFactCycle() {
        Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { _ in
            factIndex += 1
        }
    }
}

// MARK: - SMS Compose View

struct SMSComposeView: UIViewControllerRepresentable {
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            dismiss()
        }
    }
}
