import SwiftUI

// MARK: - Smoke Sensitivity

enum SmokeSensitivity: String, CaseIterable {
    case low, moderate, high, extreme

    var color: Color {
        switch self {
        case .low:      return .moochGreen
        case .moderate: return .moochAmber
        case .high:     return .moochRed
        case .extreme:  return Color(red: 0.50, green: 0.08, blue: 0.06)
        }
    }

    var detail: String {
        switch self {
        case .low:      return "Minimal impact from smoke at standard AQI levels"
        case .moderate: return "Visible quality effects begin above moderate AQI"
        case .high:     return "Rapid quality degradation during smoke events"
        case .extreme:  return "Irreversible damage within hours of smoke exposure"
        }
    }
}

// MARK: - Crop Info

struct CropInfo {
    let name: String
    let sfSymbol: String
    let color: Color
    let smokeSensitivity: SmokeSensitivity
    let harvestWindowHours: Int
    let seasonNote: String
    let smokeAQIThreshold: Int
    let valuePerAcre: Int
}

// MARK: - Crop Type

enum CropType: Int, Codable, CaseIterable {
    case unknown      = 0
    case corn         = 1
    case cotton       = 2
    case sorghum      = 4
    case soybeans     = 5
    case barley       = 21
    case winterWheat  = 24
    case alfalfa      = 36
    case tomatoes     = 54
    case grapes       = 69
    case oranges      = 72
    case almonds      = 74
    case walnuts      = 75
    case apricots     = 76
    case cherries     = 77
    case peaches      = 78
    case pistachios   = 204
    case strawberries = 206
    case olives       = 211
    case pomegranates = 217
    case lettuce      = 227

    var info: CropInfo {
        switch self {
        case .corn:
            return CropInfo(
                name: "Corn", sfSymbol: "sun.max.fill", color: Color(hex: "F5C518"),
                smokeSensitivity: .moderate, harvestWindowHours: 36,
                seasonNote: "Pollen and silk exposed during tasseling — smoke reduces pollination efficiency.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .cotton:
            return CropInfo(
                name: "Cotton", sfSymbol: "cloud.fill", color: Color(hex: "F0F0F0"),
                smokeSensitivity: .low, harvestWindowHours: 48,
                seasonNote: "Open bolls resist smoke penetration but ash can cause fiber discoloration.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .sorghum:
            return CropInfo(
                name: "Sorghum", sfSymbol: "leaf.fill", color: Color(hex: "C8A93A"),
                smokeSensitivity: .low, harvestWindowHours: 48,
                seasonNote: "Robust grain crop with minimal smoke sensitivity during grain fill.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .soybeans:
            return CropInfo(
                name: "Soybeans", sfSymbol: "circle.hexagongrid.fill", color: Color(hex: "7BA05B"),
                smokeSensitivity: .moderate, harvestWindowHours: 30,
                seasonNote: "Pod fill stage vulnerable — smoke reduces photosynthesis and bean protein content.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .barley:
            return CropInfo(
                name: "Barley", sfSymbol: "wind", color: Color(hex: "D4B483"),
                smokeSensitivity: .low, harvestWindowHours: 48,
                seasonNote: "Head fully enclosed — lower smoke exposure than open-canopy crops.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .winterWheat:
            return CropInfo(
                name: "Winter Wheat", sfSymbol: "snowflake", color: Color(hex: "E8D5A3"),
                smokeSensitivity: .low, harvestWindowHours: 48,
                seasonNote: "Dormant winter growth highly resistant to smoke particulate damage.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .alfalfa:
            return CropInfo(
                name: "Alfalfa", sfSymbol: "leaf.arrow.circlepath", color: Color(hex: "5B8C3E"),
                smokeSensitivity: .moderate, harvestWindowHours: 24,
                seasonNote: "Cut timing critical — smoke aerosols accumulate on leaves and reduce hay quality.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .tomatoes:
            return CropInfo(
                name: "Tomatoes", sfSymbol: "drop.fill", color: Color(hex: "E84040"),
                smokeSensitivity: .high, harvestWindowHours: 18,
                seasonNote: "Skin absorbs volatile phenols from smoke — fruit flavor and marketability compromised.",
                smokeAQIThreshold: 90, valuePerAcre: 3200)
        case .grapes:
            return CropInfo(
                name: "Grapes", sfSymbol: "hexagon.fill", color: Color(hex: "7B3F9E"),
                smokeSensitivity: .extreme, harvestWindowHours: 12,
                seasonNote: "Smoke taint compounds bond to grape skins and destroy the entire vintage.",
                smokeAQIThreshold: 75, valuePerAcre: 8400)
        case .oranges:
            return CropInfo(
                name: "Oranges", sfSymbol: "circle.fill", color: Color(hex: "FF8C00"),
                smokeSensitivity: .moderate, harvestWindowHours: 30,
                seasonNote: "Thick rind provides moderate protection but prolonged exposure stains fruit.",
                smokeAQIThreshold: 150, valuePerAcre: 2800)
        case .almonds:
            return CropInfo(
                name: "Almonds", sfSymbol: "diamond.fill", color: Color(hex: "C8A96E"),
                smokeSensitivity: .high, harvestWindowHours: 18,
                seasonNote: "Hull splits during harvest make nuts directly vulnerable to ash.",
                smokeAQIThreshold: 100, valuePerAcre: 5200)
        case .walnuts:
            return CropInfo(
                name: "Walnuts", sfSymbol: "square.fill", color: Color(hex: "8B6914"),
                smokeSensitivity: .high, harvestWindowHours: 18,
                seasonNote: "Smoke causes hull staining and mold — hull splits make nuts absorptive.",
                smokeAQIThreshold: 100, valuePerAcre: 4100)
        case .apricots:
            return CropInfo(
                name: "Apricots", sfSymbol: "heart.fill", color: Color(hex: "FFA040"),
                smokeSensitivity: .high, harvestWindowHours: 16,
                seasonNote: "Delicate skin absorbs smoke compounds quickly once ripening begins.",
                smokeAQIThreshold: 100, valuePerAcre: 2000)
        case .cherries:
            return CropInfo(
                name: "Cherries", sfSymbol: "suit.heart.fill", color: Color(hex: "C0392B"),
                smokeSensitivity: .high, harvestWindowHours: 14,
                seasonNote: "Thin skin cracks under ash deposit stress — bacterial infection follows rapidly.",
                smokeAQIThreshold: 100, valuePerAcre: 2000)
        case .peaches:
            return CropInfo(
                name: "Peaches", sfSymbol: "oval.fill", color: Color(hex: "FFAA6E"),
                smokeSensitivity: .high, harvestWindowHours: 16,
                seasonNote: "Fuzz traps particulates and smoke taint penetrates within hours of peak ripeness.",
                smokeAQIThreshold: 100, valuePerAcre: 2000)
        case .pistachios:
            return CropInfo(
                name: "Pistachios", sfSymbol: "pentagon.fill", color: Color(hex: "8FBC4E"),
                smokeSensitivity: .moderate, harvestWindowHours: 24,
                seasonNote: "Split shells during harvest allow ash into the nut — hull integrity matters.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .strawberries:
            return CropInfo(
                name: "Strawberries", sfSymbol: "heart.fill", color: Color(hex: "E8314E"),
                smokeSensitivity: .extreme, harvestWindowHours: 10,
                seasonNote: "Ash destroys surface tissue within hours of direct exposure.",
                smokeAQIThreshold: 60, valuePerAcre: 18000)
        case .olives:
            return CropInfo(
                name: "Olives", sfSymbol: "leaf", color: Color(hex: "808000"),
                smokeSensitivity: .moderate, harvestWindowHours: 30,
                seasonNote: "Waxy olive skin resists particulates but prolonged smoke alters oil flavor profile.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .pomegranates:
            return CropInfo(
                name: "Pomegranates", sfSymbol: "plus.circle.fill", color: Color(hex: "C0225A"),
                smokeSensitivity: .moderate, harvestWindowHours: 28,
                seasonNote: "Thick rind provides protection but prolonged smoke affects arils and juice quality.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        case .lettuce:
            return CropInfo(
                name: "Lettuce", sfSymbol: "leaf.fill", color: Color(hex: "4CAF50"),
                smokeSensitivity: .extreme, harvestWindowHours: 8,
                seasonNote: "Leafy surface absorbs smoke particulates — cannot be washed off.",
                smokeAQIThreshold: 60, valuePerAcre: 6500)
        case .unknown:
            return CropInfo(
                name: "Unknown Crop", sfSymbol: "questionmark.circle", color: Color(hex: "9E9E9E"),
                smokeSensitivity: .moderate, harvestWindowHours: 24,
                seasonNote: "Unable to determine crop type — consult local extension for specific guidance.",
                smokeAQIThreshold: 150, valuePerAcre: 2000)
        }
    }

    static var pickable: [CropType] {
        CropType.allCases.filter { $0 != .unknown }
    }

    static func from(pixelValue: Int) -> CropType {
        CropType(rawValue: pixelValue) ?? .unknown
    }
}
