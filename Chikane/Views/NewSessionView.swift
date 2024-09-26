//
//  NewSessionView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import SwiftUI
import CoreLocation
import MapKit
import Combine

struct NewSessionView: View {
    @StateObject private var viewModel: NewSessionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSessionView = false
    @State private var showingSetStartFinishLine = false
    @State private var showingTrackPicker = false
    
    init(preselectedTrack: Track? = nil) {
        _viewModel = StateObject(wrappedValue: NewSessionViewModel(preselectedTrack: preselectedTrack))
    }
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    sessionDetailsSection
                    trackSection
                    carSection
                    startSessionButton
                }
                .padding()
            }
        }
        .navigationTitle("New Session")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        })
        .sheet(isPresented: $showingTrackPicker) {
            SearchableTrackPicker(selectedTrack: $viewModel.selectedTrack)
        }
        .sheet(isPresented: $showingSetStartFinishLine) {
            if let track = viewModel.selectedTrack {
                SetStartFinishLineView(track: track) { newCoordinate in
                    viewModel.updateStartFinishLine(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
                }
            }
        }
        .fullScreenCover(isPresented: $showingSessionView) {
            if let track = viewModel.selectedTrack {
                SessionView(
                    sessionName: viewModel.sessionName,
                    track: track,
                    carId: viewModel.selectedCarId,
                    isPresented: $showingSessionView
                )
            }
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(title: Text(alertItem.title),
                  message: Text(alertItem.message),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    private var sessionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Session Details")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            CustomTextField(
                icon: "pencil",
                placeholder: "Session Name",
                text: $viewModel.sessionName
            )
            
            DatePicker("Date", selection: $viewModel.sessionDate, displayedComponents: .date)
                .foregroundColor(AppColors.text)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var trackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Track")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            if let track = viewModel.selectedTrack {
                TrackRow(track: track, isSelected: true)
                Button(action: { showingSetStartFinishLine = true }) {
                    Text("Set Start/Finish Line")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.accent)
                }
            } else {
                Text("Select a track")
                    .foregroundColor(AppColors.lightText)
            }
            
            Button(action: { showingTrackPicker = true }) {
                Text(viewModel.selectedTrack == nil ? "Select Track" : "Change Track")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var carSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Car")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            if viewModel.cars.isEmpty {
                Text("No cars available. Add a car in your garage.")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            } else {
                ForEach(viewModel.cars) { car in
                    CarSelectionRow(car: car, isSelected: car.id == viewModel.selectedCarId)
                        .onTapGesture {
                            viewModel.selectedCarId = car.id
                        }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var startSessionButton: some View {
        Button(action: {
            if viewModel.validateInput() {
                showingSessionView = true
            }
        }) {
            Text("Start Session")
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(AppColors.accent)
                .cornerRadius(10)
        }
    }
}

class NewSessionViewModel: ObservableObject {
    @Published var sessionName = ""
    @Published var sessionDate = Date()
    @Published var selectedTrack: Track?
    @Published var selectedCarId = ""
    @Published var cars: [Car] = []
    @Published var alertItem: AlertItem?
    
    private var cancellables = Set<AnyCancellable>()
    private let authManager = AuthenticationManager.shared
    private let trackDatabase = TrackDatabase.shared

    init(preselectedTrack: Track? = nil) {
        self.selectedTrack = preselectedTrack
        fetchCars()
    }
    
    func fetchCars() {
        authManager.fetchCarsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error fetching cars: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] cars in
                self?.cars = cars
                if let firstCar = cars.first, self?.selectedCarId.isEmpty == true {
                    self?.selectedCarId = firstCar.id
                }
                print("Fetched \(cars.count) cars in NewSessionViewModel")
            }
            .store(in: &cancellables)
    }

    func validateInput() -> Bool {
        guard !sessionName.isEmpty else {
            alertItem = AlertItem(title: "Invalid Input", message: "Please enter a session name.")
            return false
        }
        
        guard selectedTrack != nil else {
            alertItem = AlertItem(title: "Invalid Input", message: "Please select a track.")
            return false
        }
        
        guard !selectedCarId.isEmpty else {
            alertItem = AlertItem(title: "Invalid Input", message: "Please select a car.")
            return false
        }
        
        return true
    }
    
    func updateStartFinishLine(latitude: Double, longitude: Double) {
        guard var updatedTrack = selectedTrack else { return }
        updatedTrack.startFinishLatitude = latitude
        updatedTrack.startFinishLongitude = longitude
        selectedTrack = updatedTrack

        trackDatabase.updateStartFinishLine(for: updatedTrack.id, latitude: latitude, longitude: longitude) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Start/Finish line updated successfully")
                case .failure(let error):
                    self?.alertItem = AlertItem(title: "Error", message: "Failed to update start/finish line: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct SearchableTrackPicker: View {
    @Binding var selectedTrack: Track?
    @State private var searchText = ""
    @State private var tracks: [Track] = []
    @State private var isSearching = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search tracks", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onChange(of: searchText) { _ in
                        searchTracks()
                    }
                
                if isSearching {
                    ProgressView()
                } else if tracks.isEmpty {
                    Text("No tracks found")
                        .foregroundColor(.gray)
                } else {
                    List(tracks) { track in
                        TrackRow(track: track, isSelected: track.id == selectedTrack?.id)
                            .onTapGesture {
                                selectedTrack = track
                            }
                    }
                }
            }
            .navigationTitle("Select Track")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Confirm") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedTrack == nil)
            )
        }
        .onAppear {
            fetchAllTracks()
        }
    }
    
    private func fetchAllTracks() {
        isSearching = true
        TrackDatabase.shared.getAllTracks { result in
            DispatchQueue.main.async {
                isSearching = false
                switch result {
                case .success(let fetchedTracks):
                    self.tracks = fetchedTracks
                    print("Fetched \(fetchedTracks.count) tracks")
                    fetchedTracks.forEach { print($0.name) }
                case .failure(let error):
                    print("Error fetching tracks: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func searchTracks() {
        isSearching = true
        TrackDatabase.shared.searchTracks(query: searchText) { result in
            DispatchQueue.main.async {
                isSearching = false
                switch result {
                case .success(let filteredTracks):
                    self.tracks = filteredTracks
                    print("Filtered to \(filteredTracks.count) tracks")
                case .failure(let error):
                    print("Error searching tracks: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct TrackRow: View {
    let track: Track
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(track.name)
                    .font(.headline)
                Text("\(track.state), \(track.country)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct SetStartFinishLineView: View {
    @State private var region: MKCoordinateRegion
    @State private var pinLocation: CLLocationCoordinate2D?
    @Environment(\.presentationMode) var presentationMode
    let track: Track
    var onSave: (CLLocationCoordinate2D) -> Void
    
    init(track: Track, onSave: @escaping (CLLocationCoordinate2D) -> Void) {
        self.track = track
        self.onSave = onSave
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: track.startFinishLatitude, longitude: track.startFinishLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        _pinLocation = State(initialValue: CLLocationCoordinate2D(latitude: track.startFinishLatitude, longitude: track.startFinishLongitude))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: .none, annotationItems: pinLocation.map { [$0] } ?? []) { location in
                    MapPin(coordinate: location)
                }
                .edgesIgnoringSafeArea(.all)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            let coordinates = convertToCoordinates(point: value.location)
                            pinLocation = coordinates
                            region.center = coordinates
                        }
                )
                
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            pinLocation = region.center
                        }) {
                            Text("Drop Pin")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let location = pinLocation {
                                onSave(location)
                            }
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(pinLocation == nil)
                    }
                    .padding()
                }
            }
            .navigationTitle("Set Start/Finish Line")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func convertToCoordinates(point: CGPoint) -> CLLocationCoordinate2D {
        let mapView = MKMapView()
        mapView.region = region
        
        let pointOnMap = mapView.convert(point, toCoordinateFrom: mapView)
        return pointOnMap
    }
}

struct CarSelectionRow: View {
    let car: Car
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "car.fill")
                .foregroundColor(isSelected ? AppColors.accent : AppColors.lightText)
            
            VStack(alignment: .leading) {
                Text("\(car.year) \(car.make) \(car.model)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                if let trim = car.trim {
                    Text(trim)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.lightText)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? AppColors.accent.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}

// MARK: - Track Struct

struct Track: Identifiable, Codable {
    let id: String
    let name: String
    let country: String
    let state: String
    let latitude: Double
    let longitude: Double
    let length: Double
    var startFinishLatitude: Double
    var startFinishLongitude: Double
    let type: TrackType
    let configuration: String

    enum TrackType: String, Codable {
        case roadCourse = "roadCourse"
        case oval = "oval"
        // Add other types as needed
    }
}



// MARK: - TrackDatabase Extension

extension TrackDatabase {
    func getAllTracks(completion: @escaping (Result<[Track], Error>) -> Void) {
        // Implementation depends on how you're storing/fetching tracks
        // This is just a placeholder
        completion(.success(tracksCache))
    }
    
    func searchTracks(query: String, completion: @escaping (Result<[Track], Error>) -> Void) {
        let filteredTracks = tracksCache.filter { track in
            track.name.lowercased().contains(query.lowercased()) ||
            track.state.lowercased().contains(query.lowercased()) ||
            track.country.lowercased().contains(query.lowercased())
        }
        completion(.success(filteredTracks))
    }
    
    func updateStartFinishLine(for trackId: String, latitude: Double, longitude: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let index = tracksCache.firstIndex(where: { $0.id == trackId }) else {
            completion(.failure(NSError(domain: "TrackDatabase", code: 1, userInfo: [NSLocalizedDescriptionKey: "Track not found"])))
            return
        }
        
        tracksCache[index].startFinishLatitude = latitude
        tracksCache[index].startFinishLongitude = longitude
        
        // Here you would typically save this update to a persistent store or backend
        // For now, we'll just simulate a successful update
        completion(.success(()))
    }
}

