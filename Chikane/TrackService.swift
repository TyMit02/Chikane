//
//  TrackService.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/25/24.
//

import SwiftUI
import Foundation

class TrackService {
    static let shared = TrackService()
    
    private var tracks: [Track] = []
    
    private init() {
        loadTracks()
    }
    
    private func loadTracks() {
        guard let url = Bundle.main.url(forResource: "custom_tracks", withExtension: "json") else {
            print("Unable to find custom_tracks.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            tracks = try JSONDecoder().decode([Track].self, from: data)
        } catch {
            print("Error decoding tracks: \(error)")
        }
    }
    
    func getAllTracks() -> [Track] {
        return tracks
    }
    
    func getTracksByState(_ state: String) -> [Track] {
        return tracks.filter { $0.state == state }
    }
    
    func getTracksByCountry(_ country: String) -> [Track] {
        return tracks.filter { $0.country == country }
    }
    
    func getUniqueStates() -> [String] {
        return Array(Set(tracks.map { $0.state })).sorted()
    }
    
    func getUniqueCountries() -> [String] {
        return Array(Set(tracks.map { $0.country })).sorted()
    }
}

struct TrackListView: View {
    @State private var selectedState: String = "All States"
    @State private var tracks: [Track] = []
    
    private let trackService = TrackService.shared
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("State", selection: $selectedState) {
                    Text("All States").tag("All States")
                    ForEach(trackService.getUniqueStates(), id: \.self) { state in
                        Text(state).tag(state)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedState) { _ in
                    updateTrackList()
                }
                
                List(tracks) { track in
                    NavigationLink(destination: TrackDetailView(track: track)) {
                        VStack(alignment: .leading) {
                            Text(track.name)
                                .font(.headline)
                            Text("\(track.configuration)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Tracks")
        }
        .onAppear {
            updateTrackList()
        }
    }
    
    private func updateTrackList() {
        if selectedState == "All States" {
            tracks = trackService.getAllTracks()
        } else {
            tracks = trackService.getTracksByState(selectedState)
        }
    }
}

