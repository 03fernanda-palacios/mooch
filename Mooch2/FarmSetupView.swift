import SwiftUI
import CoreLocation

struct FarmSetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var farmName = "Valley Walnut Co."
    @State private var latitude: Double? = 39.7596
    @State private var longitude: Double? = -121.6219
    @State private var latText = "39.75960"
    @State private var lonText = "-121.62190"
    @State private var selectedCrop: CropType = .walnuts
    @State private var selectedWater: WaterSource = .canal
    @State private var acreageText = "120"
    @State private var isLocating = false
    @State private var suggestedCrop: CropType? = nil
    @State private var isSaving = false
    @State private var validationError: String? = nil

    private let locationManager = CLLocationManager()
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.moochBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    nameSection
                    locationSection
                    cropSection
                    waterSection
                    acreageSection
                    if let err = validationError {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.moochRed)
                            .padding(.horizontal, 2)
                    }
                    confirmButton
                }
                .padding(20)
            }
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEW FARM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.moochTextTertiary)
                        .tracking(2.0)
                    HStack(spacing: 8) {
                        Text("Set Up Your Field")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.moochTextPrimary)
                        Text("DEMO")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.moochAmber)
                            .tracking(1.5)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.moochAmberLight)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                if dismiss != nil {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.moochTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.moochSurface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.moochBorder, lineWidth: 1))
                    }
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.moochAmber)
                Text("Coordinates frozen at 2018 Camp Fire origin · Pulga, Butte County CA")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.moochAmber)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.moochAmberLight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.moochAmber.opacity(0.25), lineWidth: 1))
        }
    }

    // MARK: Farm Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("FARM NAME")
            TextField("e.g. Valley Oak Farm", text: $farmName)
                .font(.system(size: 16))
                .padding(14)
                .background(Color.moochSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.moochBorder, lineWidth: 1))
        }
    }

    // MARK: Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("LOCATION")
            HStack(spacing: 10) {
                Button {
                    requestGPS()
                } label: {
                    HStack(spacing: 6) {
                        if isLocating {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text(isLocating ? "Locating…" : "Use GPS")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color.moochGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                VStack(spacing: 6) {
                    CoordField("Latitude", text: $latText)
                    CoordField("Longitude", text: $lonText)
                }
            }

            if latitude != nil && longitude != nil {
                Text(String(format: "%.5f, %.5f", latitude!, longitude!))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.moochTextTertiary)
            }

            mapPreview
        }
    }

    private var mapPreview: some View {
        let farms: [FarmProfile] = latitude != nil && longitude != nil && !farmName.isEmpty
            ? [FarmProfile(name: farmName.isEmpty ? "Farm" : farmName,
                           latitude: latitude!, longitude: longitude!,
                           cropType: selectedCrop, waterSource: selectedWater)]
            : []

        return MoochMapView(
            farms: farms,
            hotspots: [],
            windDirection: "SW",
            isSetupMode: true,
            onTap: { coord in
                latitude = coord.latitude
                longitude = coord.longitude
                latText = String(format: "%.5f", coord.latitude)
                lonText = String(format: "%.5f", coord.longitude)
                Task { await detectCropAtLocation(lat: coord.latitude, lon: coord.longitude) }
            }
        )
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.moochBorder, lineWidth: 1))
    }

    // MARK: Crop Picker

    private var cropSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("CROP TYPE")
                if let suggested = suggestedCrop {
                    Spacer()
                    Button { selectedCrop = suggested } label: {
                        Text("CropScape suggests: \(suggested.info.name)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.moochAmber)
                            .tracking(0.5)
                    }
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(CropType.pickable, id: \.rawValue) { crop in
                    cropCell(crop)
                }
            }
        }
    }

    private func cropCell(_ crop: CropType) -> some View {
        let info = crop.info
        let selected = selectedCrop == crop
        return Button { selectedCrop = crop; haptic(.light) } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(selected ? info.color.opacity(0.25) : Color.moochSurface)
                        .frame(width: 40, height: 40)
                    Image(systemName: info.sfSymbol)
                        .font(.system(size: 16))
                        .foregroundColor(selected ? info.color : Color.moochTextSecondary)
                }
                Text(info.name)
                    .font(.system(size: 8, weight: selected ? .bold : .regular))
                    .foregroundColor(selected ? Color.moochTextPrimary : Color.moochTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(6)
            .background(selected ? info.color.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? info.color.opacity(0.4) : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: Water Source

    private var waterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WATER SOURCE")
            HStack(spacing: 8) {
                ForEach(WaterSource.allCases, id: \.rawValue) { source in
                    waterButton(source)
                }
            }
        }
    }

    private func waterButton(_ source: WaterSource) -> some View {
        let selected = selectedWater == source
        let icon: String
        switch source {
        case .well:      icon = "drop.fill"
        case .canal:     icon = "water.waves"
        case .reservoir: icon = "lake"
        }
        return Button {
            selectedWater = source
            haptic(.light)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(selected ? Color.moochGreen : Color.moochTextSecondary)
                Text(source.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(selected ? Color.moochTextPrimary : Color.moochTextSecondary)
                Text(source.fireNote)
                    .font(.system(size: 9))
                    .foregroundColor(Color.moochTextTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(selected ? Color.moochGreenLight : Color.moochSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? Color.moochGreen : Color.moochBorder, lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Acreage

    private var acreageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("ACREAGE")
            HStack(spacing: 8) {
                TextField("40", text: $acreageText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, design: .monospaced))
                    .padding(14)
                    .background(Color.moochSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.moochBorder, lineWidth: 1))
                Text("acres")
                    .font(.system(size: 14))
                    .foregroundColor(Color.moochTextSecondary)
            }
        }
    }

    // MARK: Confirm

    private var confirmButton: some View {
        Button {
            haptic(.heavy)
            save()
        } label: {
            HStack {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    let isParadise = abs((latitude ?? 0) - 39.7596) < 0.001
                    Text(isParadise ? "LAUNCH DEMO FARM" : "CONFIRM FARM")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canSave ? Color.moochGreen : Color.moochBorder)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!canSave || isSaving)
    }

    private var canSave: Bool {
        !farmName.trimmingCharacters(in: .whitespaces).isEmpty
            && latitude != nil && longitude != nil
    }

    private func save() {
        guard let lat = latitude, let lon = longitude else {
            validationError = "Please set a farm location."
            return
        }
        let name = farmName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            validationError = "Please enter a farm name."
            return
        }
        let acreage = Double(acreageText) ?? 40
        isSaving = true
        Task {
            let farm = FarmProfile(name: name, latitude: lat, longitude: lon,
                                   cropType: selectedCrop, waterSource: selectedWater, acreage: acreage)
            appState.saveFarm(farm)
            appState.setActiveFarm(farm.id)
            isSaving = false
            onDismiss?()
            dismiss()
        }
    }

    private func requestGPS() {
        isLocating = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Use one-shot location
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if let coord = locationManager.location?.coordinate {
                await MainActor.run {
                    latitude  = coord.latitude
                    longitude = coord.longitude
                    latText = String(format: "%.5f", coord.latitude)
                    lonText = String(format: "%.5f", coord.longitude)
                    isLocating = false
                }
                await detectCropAtLocation(lat: coord.latitude, lon: coord.longitude)
            } else {
                await MainActor.run { isLocating = false }
            }
        }
    }

    private func detectCropAtLocation(lat: Double, lon: Double) async {
        if let crop = try? await APIService.detectCrop(lat: lat, lon: lon), crop != .unknown {
            suggestedCrop = crop
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(Color.moochTextTertiary)
            .tracking(2.0)
    }
}

// MARK: - Coord Field

private struct CoordField: View {
    let placeholder: String
    @Binding var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .font(.system(size: 12, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.moochSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.moochBorder, lineWidth: 1))
    }
}
