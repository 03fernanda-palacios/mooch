import Foundation
import CoreLocation

// MARK: - API Service

enum APIService {

    // MARK: NASA FIRMS — Fire Hotspots

    static func fetchFireHotspots(lat: Double, lon: Double) async throws -> [FireHotspot] {
        let west  = lon - 2.0
        let south = lat - 2.0
        let east  = lon + 2.0
        let north = lat + 2.0
        let dateStr = isoDateString()

        let urlStr = "https://firms.modaps.eosdis.nasa.gov/api/area/csv/\(Secrets.firmsAPIKey)/VIIRS_SNPP_NRT/\(west),\(south),\(east),\(north)/1/\(dateStr)"

        guard let url = URL(string: urlStr) else { throw APIError.badURL }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.badStatus
        }

        let csv = String(data: data, encoding: .utf8) ?? ""
        return parseFIRMSCSV(csv)
    }

    static func fallbackHotspots(lat: Double, lon: Double) -> [FireHotspot] {
        [FireHotspot(latitude: lat + 0.27, longitude: lon + 0.19, brightness: 340, frp: 45)]
    }

    private static func parseFIRMSCSV(_ csv: String) -> [FireHotspot] {
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return [] }

        let header = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let latIdx  = header.firstIndex(of: "latitude"),
              let lonIdx  = header.firstIndex(of: "longitude"),
              let briIdx  = header.firstIndex(of: "bright_ti4"),
              let frpIdx  = header.firstIndex(of: "frp") else { return [] }

        return lines.dropFirst().compactMap { line -> FireHotspot? in
            let fields = line.components(separatedBy: ",")
            guard fields.count > max(latIdx, lonIdx, briIdx, frpIdx),
                  let latVal = Double(fields[latIdx].trimmingCharacters(in: .whitespaces)),
                  let lonVal = Double(fields[lonIdx].trimmingCharacters(in: .whitespaces)),
                  let briVal = Double(fields[briIdx].trimmingCharacters(in: .whitespaces)),
                  let frpVal = Double(fields[frpIdx].trimmingCharacters(in: .whitespaces))
            else { return nil }
            return FireHotspot(latitude: latVal, longitude: lonVal, brightness: briVal, frp: frpVal)
        }
    }

    // MARK: AirNow — AQI

    static func fetchAQI(lat: Double, lon: Double) async throws -> AQIData {
        var components = URLComponents(string: "https://www.airnowapi.org/aq/observation/latLong/current/")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "application/json"),
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "distance", value: "75"),
            URLQueryItem(name: "API_KEY", value: Secrets.airNowAPIKey),
        ]
        guard let url = components.url else { throw APIError.badURL }

        let (data, _) = try await URLSession.shared.data(from: url)
        let observations = try JSONDecoder().decode([AirNowObservation].self, from: data)

        let pm25 = observations.first { $0.parameterName.contains("PM2.5") }
            ?? observations.first

        guard let obs = pm25 else { throw APIError.noData }
        return AQIData(value: obs.aqi, category: obs.category.name, parameter: obs.parameterName)
    }

    // MARK: NOAA — Wind

    static func fetchWeather(lat: Double, lon: Double) async throws -> WeatherData {
        let pointURL = URL(string: "https://api.weather.gov/points/\(lat),\(lon)")!
        var request = URLRequest(url: pointURL)
        request.setValue("(mooch-app, contact@mooch.app)", forHTTPHeaderField: "User-Agent")

        let (pointData, _) = try await URLSession.shared.data(for: request)
        let pointResponse = try JSONDecoder().decode(NOAAPointsResponse.self, from: pointData)

        guard let hourlyURLStr = pointResponse.properties.forecastHourly,
              let hourlyURL = URL(string: hourlyURLStr) else { throw APIError.noData }

        var hourlyRequest = URLRequest(url: hourlyURL)
        hourlyRequest.setValue("(mooch-app, contact@mooch.app)", forHTTPHeaderField: "User-Agent")

        let (hourlyData, _) = try await URLSession.shared.data(for: hourlyRequest)
        let forecast = try JSONDecoder().decode(NOAAForecastResponse.self, from: hourlyData)

        guard let first = forecast.properties.periods.first else { throw APIError.noData }

        let speed = parseWindSpeed(first.windSpeed)
        return WeatherData(windSpeed: speed, windDirection: first.windDirection)
    }

    private static func parseWindSpeed(_ raw: String) -> Int {
        let nums = raw.components(separatedBy: .whitespaces)
        return Int(nums.first ?? "8") ?? 8
    }

    // MARK: USDA CropScape — Crop Detection

    static func detectCrop(lat: Double, lon: Double) async throws -> CropType? {
        var components = URLComponents(string: "https://nassgeodata.gmu.edu/arcgis/rest/services/CDLService/MapServer/identify")!
        components.queryItems = [
            URLQueryItem(name: "geometry", value: "\(lon),\(lat)"),
            URLQueryItem(name: "geometryType", value: "esriGeometryPoint"),
            URLQueryItem(name: "layers", value: "all"),
            URLQueryItem(name: "returnGeometry", value: "false"),
            URLQueryItem(name: "f", value: "json"),
        ]
        guard let url = components.url else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(CropScapeResponse.self, from: data)

        guard let first = result.results.first,
              let pixelStr = first.attributes["Pixel Value"],
              let pixel = Int(pixelStr)
        else { return nil }

        return CropType.from(pixelValue: pixel)
    }

    // MARK: Claude — Action Plan

    static func generateActionPlan(
        farmName: String,
        cropName: String,
        aqiValue: Int,
        aqiCategory: String,
        fireDistanceMiles: String,
        fireBearing: String,
        windDirection: String,
        windSpeed: Int,
        isDemoMode: Bool
    ) async -> String {
        let systemPrompt: String
        let userPrompt: String

        if isDemoMode {
            systemPrompt = """
            You are an emergency agricultural advisor responding to the Camp Fire, Butte County, California, November 8, 2018. \
            A walnut farmer on a 120-acre farm needs urgent guidance. The fire is 8 miles NE moving at 35 mph driven by Diablo winds. \
            AQI is 284 (Very Unhealthy). Butte Creek canal intake is compromised by fire proximity and ash loading. \
            Walnut hull-stain threshold has already been exceeded — AQI 284 is nearly 3x the safe limit of 100. \
            Be direct, specific, and urgent. Structure your response: one sentence risk assessment, then exactly 3 numbered action items. Each action item max 20 words. No fluff.
            """
            userPrompt = """
            Farm: \(farmName). Crop: \(cropName). AQI: \(aqiValue) (\(aqiCategory)). \
            Nearest fire: \(fireDistanceMiles) miles \(fireBearing) of my farm. \
            Wind blowing \(windDirection) at \(windSpeed) mph. \
            What are my 3 most urgent actions in the next 12 hours?
            """
        } else {
            systemPrompt = """
            You are an emergency agricultural advisor. A small farmer needs urgent guidance during an active wildfire event. \
            Be direct and specific. Structure your response as: one sentence risk assessment, then exactly 3 numbered action items. \
            Each action item max 20 words. No fluff.
            """
            userPrompt = """
            Farm: \(farmName). Crop: \(cropName). AQI: \(aqiValue) (\(aqiCategory)). \
            Nearest fire: \(fireDistanceMiles) miles \(fireBearing) of my farm. \
            Wind blowing \(windDirection) at \(windSpeed) mph. \
            What are my 3 most urgent actions in the next 12 hours?
            """
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return localFallbackPlan(cropName: cropName, aqiValue: aqiValue)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Secrets.claudeAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 300,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userPrompt]]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            return localFallbackPlan(cropName: cropName, aqiValue: aqiValue)
        }
        request.httpBody = bodyData

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let response = try? JSONDecoder().decode(ClaudeResponse.self, from: data),
              let text = response.content.first?.text
        else {
            return localFallbackPlan(cropName: cropName, aqiValue: aqiValue)
        }

        return text
    }

    private static func localFallbackPlan(cropName: String, aqiValue: Int) -> String {
        let threshold = 100
        let overThreshold = aqiValue > threshold
        let statusLine = overThreshold
            ? "AQI \(aqiValue) EXCEEDS safe threshold for \(cropName) — crop damage risk is active."
            : "AQI \(aqiValue) is below critical threshold for \(cropName), but monitor closely."

        return """
        \(statusLine)

        1. Assess \(cropName) crop for visible smoke or ash deposit damage immediately.
        2. Document current field conditions with photos for insurance purposes.
        3. Contact your county agricultural commissioner for emergency guidance.
        """
    }

    // MARK: Crew SMS

    static func notifyCrewText(
        farm: FarmProfile,
        aqi: Int,
        distance: Double,
        bearing: String
    ) -> String {
        let distStr = String(format: "%.1f", distance)
        let harvestAction = harvestGuidance(for: farm.cropType, aqi: aqi)
        let irrigationAction = irrigationGuidance(for: farm.waterSource, distStr: distStr, bearing: bearing)

        return """
        🔥 FIRE ALERT — \(farm.name) | AQI \(aqi) | Fire \(distStr) mi \(bearing)

        [Harvest Crew]
        \(harvestAction)

        [Irrigation Lead]
        \(irrigationAction)

        [Equipment Operator]
        Move machinery to upwind side of property. Cover exposed engines with tarps. Document all equipment locations with photos for insurance.

        Wear N95 if available. Check in with supervisor before leaving.
        """
    }

    private static func harvestGuidance(for crop: CropType, aqi: Int) -> String {
        let info = crop.info
        let over = aqi > info.smokeAQIThreshold
        switch crop {
        case .grapes:
            return over
                ? "STOP harvest immediately — smoke taint is irreversible above AQI \(info.smokeAQIThreshold). Seal any harvested bins. Do not process further until tested."
                : "Monitor AQI closely. Harvest window open but threshold (\(info.smokeAQIThreshold)) at risk."
        case .walnuts:
            return over
                ? "Harvest any split-hull walnuts NOW — exposed nuts absorb smoke within 48h. Prioritize drying yard rows furthest from fire bearing."
                : "AQI below walnut threshold (\(info.smokeAQIThreshold)). Continue harvest but monitor hull split status."
        case .almonds:
            return over
                ? "Pull harvesters to rows furthest from fire. Complete any open-hull sections within \(info.harvestWindowHours)h or loss is total."
                : "Continue almond harvest. Threshold (\(info.smokeAQIThreshold)) not yet breached — watch ash accumulation."
        case .lettuce:
            return over
                ? "TOTAL LOSS threshold exceeded — AQI \(aqi) vs safe \(info.smokeAQIThreshold). Stop harvest. Document for insurance."
                : "Harvest all ready lettuce immediately — threshold (\(info.smokeAQIThreshold)) is within range."
        case .strawberries:
            return over
                ? "HARVEST NOW or total loss. Surface tissue destroyed within \(info.harvestWindowHours)h above AQI \(info.smokeAQIThreshold)."
                : "Complete harvest immediately — strawberry window is narrow and AQI is rising."
        case .tomatoes:
            return over
                ? "Smoke phenols compromising flavor marketability. Harvest any peak-ripe fruit within \(info.harvestWindowHours)h and refrigerate."
                : "Continue harvest. AQI below tomato threshold (\(info.smokeAQIThreshold))."
        default:
            return over
                ? "AQI \(aqi) exceeds safe limit for \(info.name). Prioritize harvest of any ready crop within \(info.harvestWindowHours)h."
                : "AQI within safe range for \(info.name). Continue normal harvest operations."
        }
    }

    private static func irrigationGuidance(for source: WaterSource, distStr: String, bearing: String) -> String {
        switch source {
        case .canal:
            return "SHUT canal intake NOW — fire \(distStr) mi \(bearing) means ash and benzene contamination upstream. Switch to well backup. Document last clean-water reading for regulators."
        case .reservoir:
            return "Switch reservoir intake to deepest available port — surface ash accumulation is active. Test for turbidity before any crop irrigation. Seal pump house vents."
        case .well:
            return "Well water unaffected by surface contamination. Continue normal irrigation. Monitor pump house for ash infiltration and keep vents sealed."
        }
    }

    // MARK: Helpers

    private static func isoDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Response Models

private enum APIError: Error {
    case badURL, badStatus, noData
}

private struct AirNowObservation: Codable {
    let parameterName: String
    let aqi: Int
    let category: AirNowCategory

    enum CodingKeys: String, CodingKey {
        case parameterName = "ParameterName"
        case aqi = "AQI"
        case category = "Category"
    }
}

private struct AirNowCategory: Codable {
    let name: String
    enum CodingKeys: String, CodingKey { case name = "Name" }
}

private struct NOAAPointsResponse: Codable {
    let properties: NOAAPointsProperties
}

private struct NOAAPointsProperties: Codable {
    let forecastHourly: String?
}

private struct NOAAForecastResponse: Codable {
    let properties: NOAAForecastProperties
}

private struct NOAAForecastProperties: Codable {
    let periods: [NOAAForecastPeriod]
}

private struct NOAAForecastPeriod: Codable {
    let windSpeed: String
    let windDirection: String
}

private struct CropScapeResponse: Codable {
    let results: [CropScapeResult]
}

private struct CropScapeResult: Codable {
    let attributes: [String: String]
}

private struct ClaudeResponse: Codable {
    let content: [ClaudeContent]
}

private struct ClaudeContent: Codable {
    let text: String
    let type: String
}
