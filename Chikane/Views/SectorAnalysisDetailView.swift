import SwiftUI
import MapKit

struct SectorAnalysisDetailView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @State private var selectedSector: Int?
    @State private var mapType: MKMapType = .standard

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                sectorMap
                sectorList
                cornerAnalysis
            }
            .padding()
        }
        .navigationTitle("Sector Analysis")
    }

    private var sectorMap: some View {
        VStack {
            Picker("Map Type", selection: $mapType) {
                Text("Standard").tag(MKMapType.standard)
                Text("Satellite").tag(MKMapType.satellite)
                Text("Hybrid").tag(MKMapType.hybrid)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            SectorMapView(viewModel: viewModel, mapType: $mapType, selectedSector: $selectedSector)
                .frame(height: 300)
                .cornerRadius(10)
        }
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }

    private var sectorList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sector Details")
                .font(.headline)
            ForEach(viewModel.sectors) { sector in
                SectorRow(sector: sector)
                    .background(selectedSector == sector.id ? AppColors.accent.opacity(0.2) : Color.clear)
                    .onTapGesture {
                        selectedSector = sector.id
                    }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }

    private var cornerAnalysis: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Corner Analysis")
                .font(.headline)
            ForEach(viewModel.cornerAnalysis) { corner in
                CornerRow(corner: corner)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}

struct CornerRow: View {
    let corner: CornerAnalysis

    var body: some View {
        VStack(alignment: .leading) {
            Text("Corner \(corner.number)")
                .font(.subheadline)
            HStack {
                VStack(alignment: .leading) {
                    Text("Entry: \(String(format: "%.1f mph", corner.entrySpeed))")
                    Text("Apex: \(String(format: "%.1f mph", corner.apexSpeed))")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Exit: \(String(format: "%.1f mph", corner.exitSpeed))")
                    Text("Δ Speed: \(String(format: "%.1f mph", corner.exitSpeed - corner.entrySpeed))")
                }
            }
        }
        .padding(.vertical, 5)
    }
}

struct SectorMapView: UIViewRepresentable {
    @ObservedObject var viewModel: SessionDetailViewModel
    @Binding var mapType: MKMapType
    @Binding var selectedSector: Int?

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
            let racingLine = RacingLine(coordinates: coordinates, speeds: speeds)
            mapView.addOverlay(racingLine)

            // Add sector overlays
            for (index, sector) in viewModel.sectors.enumerated() {
                let sectorCoordinates = Array(coordinates[sector.startIndex...sector.endIndex])
                let sectorLine = SectorLine(coordinates: sectorCoordinates, sectorIndex: index)
                mapView.addOverlay(sectorLine)
            }
        }

        // Add corner annotations
        for corner in viewModel.cornerAnalysis {
            let annotation = MKPointAnnotation()
            annotation.coordinate = corner.apexPoint
            annotation.title = "Corner \(corner.number)"
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: SectorMapView

        init(_ parent: SectorMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let racingLine = overlay as? RacingLine {
                return RacingLineRenderer(racingLine: racingLine)
            } else if let sectorLine = overlay as? SectorLine {
                let renderer = MKPolylineRenderer(overlay: sectorLine)
                renderer.strokeColor = sectorColors[sectorLine.sectorIndex % sectorColors.count].withAlphaComponent(0.8)
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "corner"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            view?.markerTintColor = .purple
            return view
        }
    }
}

struct SectorLine: MKPolyline {
    let sectorIndex: Int

    init(coordinates: [CLLocationCoordinate2D], sectorIndex: Int) {
        self.sectorIndex = sectorIndex
        super.init(coordinates: coordinates, count: coordinates.count)
    }
}

let sectorColors: [UIColor] = [.red, .green, .blue, .orange, .purple, .cyan]