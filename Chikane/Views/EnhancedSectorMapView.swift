import SwiftUI
import MapKit

struct EnhancedSectorMapView: UIViewRepresentable {
    @ObservedObject var viewModel: SessionDetailViewModel
    @Binding var mapType: MKMapType
    @Binding var selectedSector: Int?
    @Binding var showHeatmap: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        mapView.setRegion(viewModel.region, animated: true)

        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        if let coordinates = viewModel.session.coordinates,
           let speeds = viewModel.session.speeds,
           !coordinates.isEmpty, coordinates.count == speeds.count {
            
            if showHeatmap {
                let heatmapOverlay = HeatmapOverlay(coordinates: coordinates, speeds: speeds)
                mapView.addOverlay(heatmapOverlay)
            } else {
                let racingLine = RacingLine(coordinates: coordinates, speeds: speeds)
                mapView.addOverlay(racingLine)
            }

            // Add sector overlays
            for (index, sector) in viewModel.sectors.enumerated() {
                let sectorCoordinates = Array(coordinates[sector.startIndex...sector.endIndex])
                let sectorLine = SectorLine(coordinates: sectorCoordinates, sectorIndex: index)
                mapView.addOverlay(sectorLine)
            }
        }

        // Add corner annotations
        for corner in viewModel.cornerAnalysis {
            let annotation = CornerAnnotation(corner: corner)
            mapView.addAnnotation(annotation)
        }

        // Add sector labels
        for (index, sector) in viewModel.sectors.enumerated() {
            if let coordinate = viewModel.session.coordinates?[sector.startIndex] {
                let annotation = SectorLabelAnnotation(coordinate: coordinate, sectorNumber: index + 1)
                mapView.addAnnotation(annotation)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: EnhancedSectorMapView

        init(_ parent: EnhancedSectorMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let heatmapOverlay = overlay as? HeatmapOverlay {
                return HeatmapRenderer(overlay: heatmapOverlay)
            } else if let racingLine = overlay as? RacingLine {
                return RacingLineRenderer(racingLine: racingLine)
            } else if let sectorLine = overlay as? SectorLine {
                let renderer = MKPolylineRenderer(polyline: sectorLine)
                renderer.strokeColor = sectorColors[sectorLine.sectorIndex % sectorColors.count].withAlphaComponent(0.8)
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let cornerAnnotation = annotation as? CornerAnnotation {
                let identifier = "corner"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if view == nil {
                    view = MKMarkerAnnotationView(annotation: cornerAnnotation, reuseIdentifier: identifier)
                    view?.canShowCallout = true
                } else {
                    view?.annotation = cornerAnnotation
                }
                view?.glyphText = "\(cornerAnnotation.corner.number)"
                view?.markerTintColor = .purple
                return view
            } else if let sectorLabel = annotation as? SectorLabelAnnotation {
                let identifier = "sectorLabel"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKAnnotationView
                if view == nil {
                    view = MKAnnotationView(annotation: sectorLabel, reuseIdentifier: identifier)
                    view?.canShowCallout = false
                } else {
                    view?.annotation = sectorLabel
                }
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                label.text = "S\(sectorLabel.sectorNumber)"
                label.textAlignment = .center
                label.textColor = .white
                label.font = UIFont.boldSystemFont(ofSize: 12)
                label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                label.layer.cornerRadius = 15
                label.layer.masksToBounds = true
                view?.addSubview(label)
                return view
            }
            return nil
        }
    }
}

class HeatmapOverlay: MKOverlay {
    let coordinates: [CLLocationCoordinate2D]
    let speeds: [Double]

    init(coordinates: [CLLocationCoordinate2D], speeds: [Double]) {
        self.coordinates = coordinates
        self.speeds = speeds
    }

    var coordinate: CLLocationCoordinate2D {
        return coordinates.first ?? CLLocationCoordinate2D()
    }

    var boundingMapRect: MKMapRect {
        let rects = coordinates.map { MKMapRect(origin: MKMapPoint($0), size: MKMapSize(width: 1, height: 1)) }
        return rects.reduce(MKMapRect.null) { $0.union($1) }
    }
}

class HeatmapRenderer: MKOverlayRenderer {
    let heatmap: HeatmapOverlay

    init(overlay: HeatmapOverlay) {
        self.heatmap = overlay
        super.init(overlay: overlay)
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let minSpeed = heatmap.speeds.min() ?? 0
        let maxSpeed = heatmap.speeds.max() ?? 1

        for (coordinate, speed) in zip(heatmap.coordinates, heatmap.speeds) {
            let point = self.point(for: coordinate)
            let normalizedSpeed = (speed - minSpeed) / (maxSpeed - minSpeed)
            let color = UIColor(hue: CGFloat(0.7 - 0.7 * normalizedSpeed), saturation: 1, brightness: 1, alpha: 0.7)
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10))
        }
    }
}

class CornerAnnotation: NSObject, MKAnnotation {
    let corner: CornerAnalysis
    var coordinate: CLLocationCoordinate2D { corner.apexPoint }
    var title: String? { "Corner \(corner.number)" }
    var subtitle: String? { "Apex Speed: \(String(format: "%.1f mph", corner.apexSpeed))" }

    init(corner: CornerAnalysis) {
        self.corner = corner
    }
}

class SectorLabelAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let sectorNumber: Int

    init(coordinate: CLLocationCoordinate2D, sectorNumber: Int) {
        self.coordinate = coordinate
        self.sectorNumber = sectorNumber
    }
}

let sectorColors: [UIColor] = [.red, .green, .blue, .orange, .purple, .cyan]