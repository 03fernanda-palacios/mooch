import Foundation
import CoreLocation
import Observation
import SwiftUI

// MARK: - Farm Profile

struct FarmProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var cropType: CropType
    var waterSource: WaterSource
    var acreage: Double
    var createdAt: Date

    init(id: UUID = UUID(), name: String, latitude: Double, longitude: Double,
         cropType: CropType = .unknown, waterSource: WaterSource = .well,
         acreage: Double = 40, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.cropType = cropType
        self.waterSource = waterSource
        self.acreage = acreage
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum WaterSource: String, Codable, CaseIterable {
    case well      = "Well"
    case canal     = "Canal"
    case reservoir = "Reservoir"

    var fireNote: String {
        switch self {
        case .well:      return "Safe from upstream ash"
        case .canal:     return "Test for ash and benzene first"
        case .reservoir: return "Use deeper intake only"
        }
    }
}

// MARK: - Fire Hotspot

struct FireHotspot: Identifiable, Codable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let brightness: Double
    let frp: Double
    var note: String?

    init(id: UUID = UUID(), latitude: Double, longitude: Double, brightness: Double, frp: Double, note: String? = nil) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.brightness = brightness
        self.frp = frp
        self.note = note
    }

    var radiusMeters: Double { max(500, min(frp * 80, 8000)) }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distanceMiles(from coord: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let to   = CLLocation(latitude: latitude, longitude: longitude)
        return from.distance(from: to) / 1609.344
    }

    func directionString(from coord: CLLocationCoordinate2D) -> String {
        let dLat = latitude - coord.latitude
        let dLon = longitude - coord.longitude
        let angle = atan2(dLon, dLat) * 180 / .pi
        let normalized = (angle + 360).truncatingRemainder(dividingBy: 360)
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((normalized + 22.5) / 45) % 8
        return dirs[index]
    }
}

// MARK: - AQI Data

struct AQIData {
    let value: Int
    let category: String
    let parameter: String

    static let fallback = AQIData(value: 142, category: "Unhealthy for Sensitive Groups", parameter: "PM2.5")

    var shortCategory: String {
        switch value {
        case 0..<51:   return "GOOD"
        case 51..<101: return "MODERATE"
        case 101..<151: return "SENSITIVE"
        case 151..<201: return "UNHEALTHY"
        case 201..<301: return "V. UNHEALTHY"
        default:        return "HAZARDOUS"
        }
    }

    var ringColor: (Double, Double, Double) {
        switch value {
        case 0..<51:   return (0.00, 0.72, 0.35)
        case 51..<101: return (1.00, 0.86, 0.00)
        case 101..<151: return (1.00, 0.52, 0.00)
        case 151..<201: return (0.85, 0.16, 0.16)
        case 201..<301: return (0.58, 0.08, 0.42)
        default:        return (0.40, 0.04, 0.04)
        }
    }
}

// MARK: - Weather Data

struct WeatherData {
    let windSpeed: Int
    let windDirection: String

    static let fallback = WeatherData(windSpeed: 8, windDirection: "SW")
}

// MARK: - App State

@Observable
class AppState {
    var farms: [FarmProfile] = []
    var activeFarmID: UUID?

    var hotspots: [FireHotspot] = []
    var aqiData: AQIData = .fallback
    var weatherData: WeatherData = .fallback
    var isLoadingData = false
    var actionPlan: String = ""
    var isLoadingPlan = false
    var isDemoMode = false

    var activeFarm: FarmProfile? {
        guard let id = activeFarmID else { return nil }
        return farms.first { $0.id == id }
    }

    var nearestHotspot: FireHotspot? {
        guard let farm = activeFarm else { return nil }
        return hotspots.min { a, b in
            a.distanceMiles(from: farm.coordinate) < b.distanceMiles(from: farm.coordinate)
        }
    }

    var nearestFireDistance: Double? {
        guard let farm = activeFarm, let spot = nearestHotspot else { return nil }
        return spot.distanceMiles(from: farm.coordinate)
    }

    var nearestFireBearing: String {
        guard let farm = activeFarm, let spot = nearestHotspot else { return "N" }
        return spot.directionString(from: farm.coordinate)
    }

    var fireAlertActive: Bool {
        (nearestFireDistance ?? Double.infinity) < 30
    }

    // MARK: Persistence

    private let farmsKey = "mooch_farms"
    private let activeKey = "mooch_active_farm"

    func loadFarms() {
        if let data = UserDefaults.standard.data(forKey: farmsKey),
           let decoded = try? JSONDecoder().decode([FarmProfile].self, from: data) {
            farms = decoded
        }
        if let idStr = UserDefaults.standard.string(forKey: activeKey),
           let id = UUID(uuidString: idStr) {
            activeFarmID = id
        }
    }

    func saveFarm(_ farm: FarmProfile) {
        isDemoMode = false
        hotspots = []
        actionPlan = ""
        if let idx = farms.firstIndex(where: { $0.id == farm.id }) {
            farms[idx] = farm
        } else {
            farms.append(farm)
        }
        persistFarms()
    }

    func deleteFarm(_ id: UUID) {
        farms.removeAll { $0.id == id }
        if activeFarmID == id { activeFarmID = farms.first?.id }
        persistFarms()
    }

    func setActiveFarm(_ id: UUID) {
        activeFarmID = id
        UserDefaults.standard.set(id.uuidString, forKey: activeKey)
    }

    func clearAllFarms() {
        farms.removeAll()
        activeFarmID = nil
        isDemoMode = false
        UserDefaults.standard.removeObject(forKey: farmsKey)
        UserDefaults.standard.removeObject(forKey: activeKey)
    }

    private func persistFarms() {
        if let data = try? JSONEncoder().encode(farms) {
            UserDefaults.standard.set(data, forKey: farmsKey)
        }
        if let id = activeFarmID {
            UserDefaults.standard.set(id.uuidString, forKey: activeKey)
        }
    }

    // MARK: Data Fetching

    func fetchAllData() async {
        guard let farm = activeFarm, !isDemoMode else { return }
        isLoadingData = true
        defer { isLoadingData = false }

        async let spots  = APIService.fetchFireHotspots(lat: farm.latitude, lon: farm.longitude)
        async let aqi    = APIService.fetchAQI(lat: farm.latitude, lon: farm.longitude)
        async let wx     = APIService.fetchWeather(lat: farm.latitude, lon: farm.longitude)

        hotspots    = (try? await spots)  ?? APIService.fallbackHotspots(lat: farm.latitude, lon: farm.longitude)
        aqiData     = (try? await aqi)    ?? .fallback
        weatherData = (try? await wx)     ?? .fallback
    }

    func generatePlan() async {
        guard let farm = activeFarm else { return }
        isLoadingPlan = true
        defer { isLoadingPlan = false }

        let dist = nearestFireDistance.map { String(format: "%.1f", $0) } ?? "unknown"
        let bearing = nearestFireBearing

        async let plan = APIService.generateActionPlan(
            farmName: farm.name,
            cropName: farm.cropType.info.name,
            aqiValue: aqiData.value,
            aqiCategory: aqiData.category,
            fireDistanceMiles: dist,
            fireBearing: bearing,
            windDirection: weatherData.windDirection,
            windSpeed: weatherData.windSpeed,
            isDemoMode: isDemoMode
        )
        try? await Task.sleep(nanoseconds: 2_800_000_000)
        actionPlan = await plan
    }

    // MARK: Demo

    func loadDemoData() {
        isDemoMode = true
        let paradiseFarm = FarmProfile(
            id: UUID(),
            name: "Paradise Farm",
            latitude: 39.7596,
            longitude: -121.6219,
            cropType: .walnuts,
            waterSource: .canal,
            acreage: 120
        )
        let magaliaVineyard = FarmProfile(
            id: UUID(),
            name: "Magalia Vineyard",
            latitude: 39.8034,
            longitude: -121.5781,
            cropType: .grapes,
            waterSource: .well,
            acreage: 65
        )
        let butteGreens = FarmProfile(
            id: UUID(),
            name: "Butte Greens",
            latitude: 39.7245,
            longitude: -121.5896,
            cropType: .lettuce,
            waterSource: .reservoir,
            acreage: 45
        )
        farms = [paradiseFarm, magaliaVineyard, butteGreens]
        activeFarmID = paradiseFarm.id

        hotspots = [
            FireHotspot(latitude: 39.8292, longitude: -121.4820, brightness: 412, frp: 98, note: "Pulga Ignition Point"),
            FireHotspot(latitude: 39.8534, longitude: -121.5012, brightness: 388, frp: 74),
            FireHotspot(latitude: 39.8101, longitude: -121.4600, brightness: 356, frp: 61),
            FireHotspot(latitude: 39.8745, longitude: -121.4430, brightness: 445, frp: 112, note: "Camp Fire Peak Spread Zone"),
            FireHotspot(latitude: 39.7980, longitude: -121.4950, brightness: 334, frp: 52),
        ]
        aqiData = AQIData(value: 284, category: "Very Unhealthy", parameter: "PM2.5")
        weatherData = WeatherData(windSpeed: 35, windDirection: "NE")
    }
}
