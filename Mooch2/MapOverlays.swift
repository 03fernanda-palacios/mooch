import MapKit
import CoreLocation
import UIKit
import SwiftUI

// MARK: - Fire Annotation

final class FireAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let hotspot: FireHotspot
    let windDirection: String

    init(hotspot: FireHotspot, windDirection: String) {
        self.hotspot = hotspot
        self.coordinate = hotspot.coordinate
        self.windDirection = windDirection
    }
}

// MARK: - Farm Annotation

final class FarmAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let farmName: String
    let cropType: CropType
    let aqiValue: Int

    init(farm: FarmProfile, aqiValue: Int) {
        self.coordinate = farm.coordinate
        self.title = farm.name
        self.farmName = farm.name
        self.cropType = farm.cropType
        self.aqiValue = aqiValue
    }

    var riskTint: UIColor {
        let info = cropType.info
        let over = aqiValue > info.smokeAQIThreshold
        let harvestNow: Set<CropType> = [.strawberries, .grapes, .lettuce, .cherries]
        if over && harvestNow.contains(cropType) { return UIColor(red: 0.75, green: 0.22, blue: 0.17, alpha: 1) }
        if over { return UIColor(red: 0.78, green: 0.41, blue: 0.04, alpha: 1) }
        return UIColor(red: 0.18, green: 0.42, blue: 0.18, alpha: 1)
    }
}

// MARK: - Fire Annotation View

final class FireAnnotationView: MKAnnotationView {
    private let outerRing = CAShapeLayer()
    private let midRing   = CAShapeLayer()
    private let centerDot = CAShapeLayer()
    private var emitterLayer: CAEmitterLayer?

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupLayers()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var annotation: (any MKAnnotation)? {
        didSet {
            if let fire = annotation as? FireAnnotation {
                updateEmitterDirection(fire.windDirection)
            }
        }
    }

    private func setupLayers() {
        frame = CGRect(x: 0, y: 0, width: 72, height: 72)
        centerOffset = .zero
        clipsToBounds = false
        backgroundColor = .clear

        let center = CGPoint(x: 36, y: 36)

        // Outer ring
        let outerPath = UIBezierPath(arcCenter: center, radius: 34, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        outerRing.path = outerPath.cgPath
        outerRing.fillColor   = UIColor.clear.cgColor
        outerRing.strokeColor = UIColor(red: 1.00, green: 0.30, blue: 0.04, alpha: 0.65).cgColor
        outerRing.lineWidth   = 2.0
        outerRing.frame       = bounds
        layer.addSublayer(outerRing)

        // Mid ring
        let midPath = UIBezierPath(arcCenter: center, radius: 20, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        midRing.path = midPath.cgPath
        midRing.fillColor   = UIColor(red: 1.00, green: 0.30, blue: 0.04, alpha: 0.18).cgColor
        midRing.strokeColor = UIColor(red: 0.95, green: 0.28, blue: 0.10, alpha: 0.45).cgColor
        midRing.lineWidth   = 1.5
        midRing.frame       = bounds
        layer.addSublayer(midRing)

        // Center dot
        let dotPath = UIBezierPath(arcCenter: center, radius: 6, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        centerDot.path        = dotPath.cgPath
        centerDot.fillColor   = UIColor(red: 1.00, green: 0.45, blue: 0.04, alpha: 0.90).cgColor
        centerDot.strokeColor = UIColor.clear.cgColor
        centerDot.frame       = bounds
        layer.addSublayer(centerDot)

        addPulseAnimations()
        addEmberLayer(windDirection: "SW")
    }

    private func addPulseAnimations() {
        // Outer ring: scale + opacity
        let outerScale = CAKeyframeAnimation(keyPath: "transform.scale")
        outerScale.values    = [1.0, 1.18, 1.0]
        outerScale.duration  = 2.8
        outerScale.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        outerScale.repeatCount = .infinity
        outerRing.add(outerScale, forKey: "outerScale")

        let outerOpacity = CAKeyframeAnimation(keyPath: "opacity")
        outerOpacity.values       = [0.9, 0.3, 0.9]
        outerOpacity.duration     = 2.8
        outerOpacity.repeatCount  = .infinity
        outerRing.add(outerOpacity, forKey: "outerOpacity")

        // Mid ring: offset phase
        let midScale = CAKeyframeAnimation(keyPath: "transform.scale")
        midScale.values    = [1.0, 1.12, 1.0]
        midScale.duration  = 2.0
        midScale.timingFunctions = [
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        midScale.repeatCount  = .infinity
        midScale.beginTime    = CACurrentMediaTime() + 0.5
        midRing.add(midScale, forKey: "midScale")
    }

    private func addEmberLayer(windDirection: String) {
        emitterLayer?.removeFromSuperlayer()

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: 36, y: 36)
        emitter.emitterSize     = CGSize(width: 8, height: 8)
        emitter.emitterShape    = .circle
        emitter.renderMode      = .additive
        emitter.frame           = bounds

        let cell = CAEmitterCell()
        cell.birthRate   = 7
        cell.lifetime    = 3.2
        cell.velocity    = 18
        cell.velocityRange = 6
        cell.emissionRange = 0.4
        cell.emissionLongitude = downwindAngle(from: windDirection)
        cell.scale       = 0.6
        cell.scaleRange  = 0.3
        cell.alphaSpeed  = -0.3
        cell.color       = UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.85).cgColor
        cell.contents    = makeEmberImage().cgImage

        emitter.emitterCells = [cell]
        layer.insertSublayer(emitter, below: centerDot)
        emitterLayer = emitter
    }

    private func makeEmberImage() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let center = CGPoint(x: 5, y: 5)
            let colors = [UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0).cgColor,
                          UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.0).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors, locations: [0, 1])!
            ctx.cgContext.drawRadialGradient(gradient,
                                             startCenter: center, startRadius: 0,
                                             endCenter: center, endRadius: 5,
                                             options: [])
        }
    }

    private func downwindAngle(from windDirection: String) -> CGFloat {
        // Wind direction = where wind comes FROM; embers travel in opposite direction
        let fromBearings: [String: Double] = [
            "N": 180, "NNE": 202.5, "NE": 225, "ENE": 247.5,
            "E": 270, "ESE": 292.5, "SE": 315, "SSE": 337.5,
            "S": 0,   "SSW": 22.5, "SW": 45,   "WSW": 67.5,
            "W": 90,  "WNW": 112.5, "NW": 135, "NNW": 157.5
        ]
        let bearing = fromBearings[windDirection] ?? 225
        // Convert from compass bearing (N=0, clockwise) to math angle (E=0, counterclockwise)
        let mathAngle = (90 - bearing) * .pi / 180
        return CGFloat(mathAngle)
    }

    func updateEmitterDirection(_ windDirection: String) {
        emitterLayer?.emitterCells?.first?.emissionLongitude = downwindAngle(from: windDirection)
    }
}

// MARK: - Farm Annotation View

final class FarmAnnotationView: MKMarkerAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout  = false
        displayPriority = .required
        updateForAnnotation()
    }
    required init?(coder: NSCoder) { fatalError() }

    override var annotation: (any MKAnnotation)? {
        didSet { updateForAnnotation() }
    }

    private func updateForAnnotation() {
        guard let farm = annotation as? FarmAnnotation else {
            markerTintColor = UIColor(red: 0.20, green: 0.50, blue: 0.20, alpha: 1.0)
            glyphImage      = UIImage(systemName: "house.fill")
            glyphTintColor  = .white
            return
        }
        markerTintColor = farm.riskTint
        glyphText       = farm.cropType.info.emoji
    }
}

// MARK: - Fire Circle Overlay

final class FireCircleOverlay: MKCircle {
    var frp: Double = 0
    static func make(hotspot: FireHotspot) -> FireCircleOverlay {
        let overlay = FireCircleOverlay(center: hotspot.coordinate, radius: hotspot.radiusMeters)
        overlay.frp = hotspot.frp
        return overlay
    }
}

// MARK: - Fire Circle Renderer

final class FireCircleRenderer: MKCircleRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard overlay is MKCircle else { return }

        let rect = self.rect(for: mapRect)
        context.saveGState()
        context.clip(to: rect)

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) / 2

        let colors = [
            UIColor(red: 1.00, green: 0.30, blue: 0.04, alpha: 0.68).cgColor,
            UIColor(red: 0.95, green: 0.28, blue: 0.10, alpha: 0.30).cgColor,
            UIColor(red: 0.90, green: 0.22, blue: 0.08, alpha: 0.00).cgColor,
        ] as CFArray
        let locations: [CGFloat] = [0, 0.48, 1.0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
            context.drawRadialGradient(gradient,
                                       startCenter: center, startRadius: 0,
                                       endCenter: center, endRadius: radius,
                                       options: .drawsAfterEndLocation)
        }

        context.setStrokeColor(UIColor(red: 0.90, green: 0.22, blue: 0.08, alpha: 0.45).cgColor)
        context.setLineWidth(1.2 / zoomScale)
        context.strokeEllipse(in: rect.insetBy(dx: 1/zoomScale, dy: 1/zoomScale))

        context.restoreGState()
    }
}

// MARK: - Farm Boundary Overlay / Renderer

final class FarmBoundaryOverlay: MKCircle {}

final class FarmBoundaryRenderer: MKCircleRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let rect = self.rect(for: mapRect)
        context.saveGState()

        let dashLen = 10.0 / zoomScale
        let gapLen  = 6.0 / zoomScale
        context.setLineDash(phase: 0, lengths: [dashLen, gapLen])
        context.setStrokeColor(UIColor(red: 0.20, green: 0.50, blue: 0.20, alpha: 0.70).cgColor)
        context.setFillColor(UIColor(red: 0.20, green: 0.50, blue: 0.20, alpha: 0.10).cgColor)
        context.setLineWidth(2.5 / zoomScale)

        context.fillEllipse(in: rect)
        context.strokeEllipse(in: rect)
        context.restoreGState()
    }
}

// MARK: - Threat Zone Overlay / Renderer

final class ThreatZoneOverlay: MKCircle {
    enum Level { case danger, warning, watch }
    var level: Level = .watch

    static func danger(center: CLLocationCoordinate2D) -> ThreatZoneOverlay {
        let o = ThreatZoneOverlay(center: center, radius: 5 * 1609.344); o.level = .danger; return o
    }
    static func warning(center: CLLocationCoordinate2D) -> ThreatZoneOverlay {
        let o = ThreatZoneOverlay(center: center, radius: 15 * 1609.344); o.level = .warning; return o
    }
    static func watch(center: CLLocationCoordinate2D) -> ThreatZoneOverlay {
        let o = ThreatZoneOverlay(center: center, radius: 30 * 1609.344); o.level = .watch; return o
    }
}

final class ThreatZoneRenderer: MKCircleRenderer {
    var level: ThreatZoneOverlay.Level = .watch

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let rect = self.rect(for: mapRect)
        context.saveGState()

        let (r, g, b, fillA, strokeA): (CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
        switch level {
        case .danger:  (r, g, b, fillA, strokeA) = (0.94, 0.12, 0.06, 0.11, 0.65)
        case .warning: (r, g, b, fillA, strokeA) = (0.94, 0.47, 0.06, 0.07, 0.45)
        case .watch:   (r, g, b, fillA, strokeA) = (0.96, 0.78, 0.05, 0.04, 0.30)
        }

        context.setFillColor(UIColor(red: r, green: g, blue: b, alpha: fillA).cgColor)
        context.fillEllipse(in: rect)

        let dashLen = 12.0 / zoomScale
        let gapLen  = 8.0 / zoomScale
        context.setLineDash(phase: 0, lengths: [dashLen, gapLen])
        context.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: strokeA).cgColor)
        context.setLineWidth(2.0 / zoomScale)
        context.strokeEllipse(in: rect)
        context.restoreGState()
    }
}

// MARK: - Smoke Drift Overlay / Renderer

final class SmokeDriftOverlay: MKPolygon {
    static func make(from coord: CLLocationCoordinate2D, windDirection: String) -> SmokeDriftOverlay {
        let bearing = compassBearing(from: windDirection)
        let spread: Double = 35
        let dist: Double = 40000

        var coords = [coord]
        let steps = 10
        for i in 0...steps {
            let angle = bearing - spread + (Double(i) / Double(steps)) * (spread * 2)
            let rad = angle * .pi / 180
            let lat = coord.latitude  + (dist / 111320) * cos(rad)
            let lon = coord.longitude + (dist / (111320 * cos(coord.latitude * .pi / 180))) * sin(rad)
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return SmokeDriftOverlay(coordinates: &coords, count: coords.count)
    }

    private static func compassBearing(from windDirection: String) -> Double {
        let map: [String: Double] = [
            "N": 0, "NNE": 22.5, "NE": 45, "ENE": 67.5,
            "E": 90, "ESE": 112.5, "SE": 135, "SSE": 157.5,
            "S": 180, "SSW": 202.5, "SW": 225, "WSW": 247.5,
            "W": 270, "WNW": 292.5, "NW": 315, "NNW": 337.5
        ]
        // wind direction = FROM; smoke drifts in opposite direction
        let from = map[windDirection] ?? 225
        return (from + 180).truncatingRemainder(dividingBy: 360)
    }
}

final class SmokeDriftRenderer: MKPolygonRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }

    override func createPath() {
        fillColor   = UIColor(red: 0.52, green: 0.42, blue: 0.32, alpha: 0.16)
        strokeColor = UIColor(red: 0.52, green: 0.42, blue: 0.32, alpha: 0.28)
        lineWidth   = 1.5
        super.createPath()
    }
}

// MARK: - CropScape Tile Overlay

final class CropScapeTileOverlay: MKTileOverlay {
    init() {
        // WMS URL template — bbox is substituted by MKTileOverlay
        let template = "https://nassgeodata.gmu.edu/arcgis/services/CDLService/MapServer/WMSServer?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&LAYERS=0&SRS=EPSG:4326&BBOX={minX},{minY},{maxX},{maxY}&WIDTH=256&HEIGHT=256&FORMAT=image%2Fpng&TRANSPARENT=TRUE"
        super.init(urlTemplate: template)
        minimumZ = 6
        maximumZ = 16
        canReplaceMapContent = false
    }
}

// MARK: - Mooch Map View

struct MoochMapView: UIViewRepresentable {
    var farms: [FarmProfile]
    var hotspots: [FireHotspot]
    var windDirection: String
    var aqiValue: Int
    var isSetupMode: Bool
    var onTap: ((CLLocationCoordinate2D) -> Void)?

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.isScrollEnabled  = true
        map.isZoomEnabled    = true
        map.isRotateEnabled  = false
        map.delegate         = context.coordinator
        map.showsUserLocation = false

        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        map.preferredConfiguration = config

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        map.addGestureRecognizer(tap)

        if isSetupMode {
            let california = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5, longitude: -119.5),
                span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
            )
            map.setRegion(california, animated: false)
        }

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        context.coordinator.update(map: map, farms: farms, hotspots: hotspots,
                                   windDirection: windDirection, aqiValue: aqiValue,
                                   isSetupMode: isSetupMode)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        var onTap: ((CLLocationCoordinate2D) -> Void)?
        private var lastFarmCoord: CLLocationCoordinate2D?
        private var lastHotspotCount = 0
        private var lastFirstHotspotID: UUID?

        init(onTap: ((CLLocationCoordinate2D) -> Void)?) {
            self.onTap = onTap
        }

        func update(map: MKMapView, farms: [FarmProfile], hotspots: [FireHotspot],
                    windDirection: String, aqiValue: Int, isSetupMode: Bool) {
            guard !isSetupMode else {
                updateSetupAnnotations(map: map, farms: farms)
                return
            }

            let farmCoord = farms.first?.coordinate
            let coordChanged = farmCoord.map { !coordEqual($0, lastFarmCoord) } ?? false
            let hotspotChanged = hotspots.count != lastHotspotCount || hotspots.first?.id != lastFirstHotspotID

            if coordChanged || hotspotChanged {
                map.removeAnnotations(map.annotations)
                map.removeOverlays(map.overlays)

                map.addOverlay(CropScapeTileOverlay(), level: .aboveRoads)

                if let farm = farms.first {
                    let farmBoundary = FarmBoundaryOverlay(center: farm.coordinate,
                                                           radius: sqrt(farm.acreage * 4046.86) * 0.5)
                    map.addOverlay(farmBoundary, level: .aboveRoads)
                    map.addOverlay(ThreatZoneOverlay.watch(center: farm.coordinate), level: .aboveRoads)
                    map.addOverlay(ThreatZoneOverlay.warning(center: farm.coordinate), level: .aboveRoads)
                    map.addOverlay(ThreatZoneOverlay.danger(center: farm.coordinate), level: .aboveRoads)
                    map.addOverlay(SmokeDriftOverlay.make(from: farm.coordinate, windDirection: windDirection), level: .aboveRoads)
                    map.addAnnotation(FarmAnnotation(farm: farm, aqiValue: aqiValue))
                }

                for hotspot in hotspots {
                    map.addOverlay(FireCircleOverlay.make(hotspot: hotspot), level: .aboveRoads)
                    map.addAnnotation(FireAnnotation(hotspot: hotspot, windDirection: windDirection))
                }

                autoZoom(map: map, farms: farms, hotspots: hotspots)
                lastFarmCoord = farmCoord
                lastHotspotCount = hotspots.count
                lastFirstHotspotID = hotspots.first?.id
            }
        }

        private func updateSetupAnnotations(map: MKMapView, farms: [FarmProfile]) {
            map.removeAnnotations(map.annotations)
            for farm in farms {
                map.addAnnotation(FarmAnnotation(farm: farm, aqiValue: 0))
            }
        }

        private func autoZoom(map: MKMapView, farms: [FarmProfile], hotspots: [FireHotspot]) {
            var coords: [CLLocationCoordinate2D] = farms.map { $0.coordinate }
            coords += hotspots.map { $0.coordinate }
            guard !coords.isEmpty else { return }

            var minLat = coords[0].latitude, maxLat = coords[0].latitude
            var minLon = coords[0].longitude, maxLon = coords[0].longitude
            for c in coords {
                minLat = min(minLat, c.latitude);  maxLat = max(maxLat, c.latitude)
                minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
            }
            let padding = 1.7
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
                span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * padding + 0.05,
                                       longitudeDelta: (maxLon - minLon) * padding + 0.05)
            )
            map.setRegion(region, animated: true)
        }

        private func coordEqual(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D?) -> Bool {
            guard let b = b else { return false }
            return abs(a.latitude - b.latitude) < 0.0001 && abs(a.longitude - b.longitude) < 0.0001
        }

        // MARK: MKMapViewDelegate

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            if let fire = annotation as? FireAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "fire") as? FireAnnotationView
                    ?? FireAnnotationView(annotation: fire, reuseIdentifier: "fire")
                view.annotation = fire
                return view
            }
            if let farm = annotation as? FarmAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "farm") as? FarmAnnotationView
                    ?? FarmAnnotationView(annotation: farm, reuseIdentifier: "farm")
                view.annotation = farm
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            switch overlay {
            case let circle as FireCircleOverlay:
                let r = FireCircleRenderer(circle: circle)
                return r
            case let boundary as FarmBoundaryOverlay:
                return FarmBoundaryRenderer(circle: boundary)
            case let threat as ThreatZoneOverlay:
                let r = ThreatZoneRenderer(circle: threat)
                r.level = threat.level
                return r
            case let smoke as SmokeDriftOverlay:
                return SmokeDriftRenderer(polygon: smoke)
            case let tile as CropScapeTileOverlay:
                let r = MKTileOverlayRenderer(tileOverlay: tile)
                r.alpha = 0.25
                return r
            default:
                return MKOverlayRenderer(overlay: overlay)
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            onTap?(coord)
        }
    }
}

private extension CLLocationCoordinate2D {
    static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
