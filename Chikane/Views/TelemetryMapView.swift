import SwiftUI
import MapKit

struct TelemetryMapView: UIViewRepresentable {
    @ObservedObject var viewModel: SessionDetailViewModel
    @State private var selectedPoint: TelemetryPoint?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateMapOverlays(mapView)
        updateMapRegion(mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateMapOverlays(_ mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        
        if let coordinates = viewModel.session.coordinates,
           let speeds = viewModel.session.speeds,
           !coordinates.isEmpty, coordinates.count == speeds.count {
            let telemetryOverlay = TelemetryOverlay(coordinates: coordinates, speeds: speeds)
            mapView.addOverlay(telemetryOverlay)
        }
        
        // Add sector overlays
        for (index, sector) in viewModel.sectors.enumerated() {
            if let coordinates = viewModel.session.coordinates {
                let sectorCoordinates = Array(coordinates[sector.startIndex...sector.endIndex])
                let sectorOverlay = SectorOverlay(coordinates: sectorCoordinates, sectorIndex: index)
                mapView.addOverlay(sectorOverlay)
            }
        }
    }
    
    private func updateMapRegion(_ mapView: MKMapView) {
        if let coordinates = viewModel.session.coordinates, !coordinates.isEmpty {
            let region = MKCoordinateRegion(coordinates: coordinates)
            mapView.setRegion(region, animated: true)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TelemetryMapView
        
        init(_ parent: TelemetryMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let telemetryOverlay = overlay as? TelemetryOverlay {
                return TelemetryOverlayRenderer(telemetryOverlay: telemetryOverlay)
            } else if let sectorOverlay = overlay as? SectorOverlay {
                return SectorOverlayRenderer(sectorOverlay: sectorOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}