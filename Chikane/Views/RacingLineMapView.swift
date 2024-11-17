import SwiftUI
import MapKit

struct RacingLineMapView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @State private var mapType: MKMapType = .satellite
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fastest Lap Racing Line")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Picker("Map Type", selection: $mapType) {
                Text("Standard").tag(MKMapType.standard)
                Text("Satellite").tag(MKMapType.satellite)
                Text("Hybrid").tag(MKMapType.hybrid)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            MapView(coordinateRegion: $viewModel.region, 
                    telemetryPoints: viewModel.fastestLapTelemetry,
                    mapType: mapType)
                .frame(height: 300)
                .cornerRadius(10)
                .onAppear {
                    viewModel.fitMapToTrack()
                    debugPrintRacingLineInfo()
                }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private func debugPrintRacingLineInfo() {
        print("Debug: Racing Line Information")
        print("Number of telemetry points: \(viewModel.fastestLapTelemetry.count)")
        print("First coordinate: \(viewModel.fastestLapTelemetry.first?.coordinate ?? CLLocationCoordinate2D())")
        print("Last coordinate: \(viewModel.fastestLapTelemetry.last?.coordinate ?? CLLocationCoordinate2D())")
        print("Max speed: \(viewModel.session.maxSpeed)")
        print("Region center: \(viewModel.region.center)")
        print("Region span: \(viewModel.region.span)")
    }
}

struct MapView: UIViewRepresentable {
    @Binding var coordinateRegion: MKCoordinateRegion
    let telemetryPoints: [TelemetryPoint]
    let mapType: MKMapType
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType
        mapView.setRegion(coordinateRegion, animated: true)
        
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add racing line overlay
        let coordinates = telemetryPoints.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        // Add point annotations
        let annotations = telemetryPoints.map { TelemetryAnnotation(telemetryPoint: $0) }
        mapView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .red
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let telemetryAnnotation = annotation as? TelemetryAnnotation else { return nil }
            
            let identifier = "TelemetryPoint"
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.markerTintColor = colorForSpeed(telemetryAnnotation.speed)
            annotationView.glyphImage = UIImage(systemName: "circle.fill")
            annotationView.glyphTintColor = .white
            annotationView.displayPriority = .defaultLow
            
            return annotationView
        }
        
        private func colorForSpeed(_ speed: Double) -> UIColor {
            let normalizedSpeed = speed / (parent.telemetryPoints.map { $0.speed }.max() ?? 1)
            return UIColor(hue: CGFloat(0.3 * normalizedSpeed), saturation: 1, brightness: 1, alpha: 1)
        }
    }
}

class TelemetryAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let speed: Double
    
    init(telemetryPoint: TelemetryPoint) {
        self.coordinate = telemetryPoint.coordinate
        self.speed = telemetryPoint.speed
        super.init()
    }
}