import SwiftUI

struct FarmListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingFarm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.moochBackground.ignoresSafeArea()

                if appState.farms.isEmpty {
                    emptyState
                } else {
                    farmList
                }
            }
            .navigationTitle("My Farms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.moochGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isAddingFarm = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.moochGreen)
                    }
                }
            }
            .sheet(isPresented: $isAddingFarm) {
                FarmSetupView()
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.moochTextTertiary)
            Text("No Farms Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.moochTextPrimary)
            Text("Add your first farm to start monitoring wildfire risk.")
                .font(.system(size: 14))
                .foregroundColor(Color.moochTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button { isAddingFarm = true } label: {
                Label("Add Farm", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(Color.moochGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button {
                haptic(.heavy)
                appState.loadDemoData()
                dismiss()
            } label: {
                // Demo: loads Paradise Farm — Camp Fire wildfire scenario
                Text("Load Demo: Paradise Farm")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.moochTextTertiary)
            }
        }
    }

    // MARK: Farm List

    private var farmList: some View {
        List {
            ForEach(appState.farms) { farm in
                farmRow(farm)
                    .listRowBackground(Color.moochBackground)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .onTapGesture {
                        haptic(.light)
                        appState.setActiveFarm(farm.id)
                        dismiss()
                    }
            }
            .onDelete { indexSet in
                for idx in indexSet {
                    appState.deleteFarm(appState.farms[idx].id)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func farmRow(_ farm: FarmProfile) -> some View {
        let info = farm.cropType.info
        let aqi = appState.activeFarmID == farm.id ? appState.aqiData.value : 0
        let riskColor = riskDotColor(farm: farm, aqi: aqi)
        let isActive = appState.activeFarmID == farm.id

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(info.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: info.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundColor(info.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(farm.name)
                    .font(.system(size: 15, weight: isActive ? .bold : .regular))
                    .foregroundColor(Color.moochTextPrimary)
                HStack(spacing: 6) {
                    Text(info.name)
                        .font(.system(size: 12))
                        .foregroundColor(Color.moochTextSecondary)
                    Text("·")
                        .foregroundColor(Color.moochTextTertiary)
                    Text("\(Int(farm.acreage)) ac")
                        .font(.system(size: 12))
                        .foregroundColor(Color.moochTextSecondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(riskColor)
                    .frame(width: 8, height: 8)
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.moochGreen)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func riskDotColor(farm: FarmProfile, aqi: Int) -> Color {
        guard appState.activeFarmID == farm.id else { return Color.moochTextTertiary }
        if appState.fireAlertActive { return .moochRed }
        if aqi > farm.cropType.info.smokeAQIThreshold { return .moochAmber }
        return .moochGreen
    }
}

#Preview {
    let state = AppState()
    state.loadDemoData()
    return FarmListView().environment(state)
}
