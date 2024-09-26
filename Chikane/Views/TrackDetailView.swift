//
//  TrackDetailView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import SwiftUI
import MapKit

struct TrackDetailView: View {
    let track: Track
    @State private var region: MKCoordinateRegion
    
    init(track: Track) {
        self.track = track
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: track.latitude, longitude: track.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    var body: some View {
        VStack {
            Map(coordinateRegion: $region, annotationItems: [track]) { track in
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: track.latitude, longitude: track.longitude))
            }
            .frame(height: 300)
            
            List {
                Section(header: Text("Track Information")) {
                    LabeledContent("Name", value: track.name)
                    LabeledContent("Country", value: track.country)
                    LabeledContent("State", value: track.state)
                    LabeledContent("Latitude", value: String(format: "%.6f", track.latitude))
                    LabeledContent("Longitude", value: String(format: "%.6f", track.longitude))
                    LabeledContent("Length", value: String(format: "%.2f km", track.length))
                    LabeledContent("Type", value: track.type.rawValue)
                    LabeledContent("Configuration", value: track.configuration)
                }
                
                Section(header: Text("Start/Finish Line")) {
                    LabeledContent("Latitude", value: String(format: "%.6f", track.startFinishLatitude))
                    LabeledContent("Longitude", value: String(format: "%.6f", track.startFinishLongitude))
                }
                
                // You could add more sections here, such as track records, upcoming events, etc.
            }
        }
        .navigationTitle(track.name)
    }
}
