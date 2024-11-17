//
//  EventCreationViewModel.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Firebase

class EventCreationViewModel: ObservableObject {
    @Published var eventName: String = ""
    @Published var eventDate: Date = Date()
    @Published var selectedTrack: Track?
    @Published var tracks: [Track] = []
    @Published var eventCode: String = ""
    @Published var isLoading: Bool = false
    var tracksCache: [Track] = []
    
    private var db = Firestore.firestore()
    
    init() {
        fetchTracks()
    }
    
    func fetchTracks() {
        isLoading = true
        
        guard let url = Bundle.main.url(forResource: "custom_tracks", withExtension: "json") else {
            print("Error: custom_tracks.json file not found")
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let fetchedTracks = try decoder.decode([Track].self, from: data)
            
            DispatchQueue.main.async {
                self.tracks = fetchedTracks
                self.tracksCache = fetchedTracks
                self.selectedTrack = fetchedTracks.first
                print("Fetched \(fetchedTracks.count) tracks")
                self.isLoading = false
            }
        } catch {
            print("Error decoding tracks: \(error)")
            isLoading = false
        }
    }
    
    func createEvent() {
        guard let userId = Auth.auth().currentUser?.uid, let track = selectedTrack else {
            print("No user logged in or no track selected")
            return
        }
        
        isLoading = true
        let newEventCode = generateEventCode()
        
        let newEvent = Event(
            name: eventName,
            date: eventDate,
            track: track.name,
            trackId: track.id,
            organizerId: userId,
            eventCode: newEventCode,
            participants: []
        )
        
        do {
            try db.collection("events").addDocument(from: newEvent) { error in
                self.isLoading = false
                if let error = error {
                    print("Error creating event: \(error.localizedDescription)")
                } else {
                    self.eventCode = newEventCode
                    print("Event created successfully with code: \(newEventCode)")
                }
            }
        } catch {
            isLoading = false
            print("Error encoding event: \(error.localizedDescription)")
        }
    }
    
    private func generateEventCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let codeLength = 6
        var code = ""
        
        for _ in 0..<codeLength {
            if Bool.random() {
                code += String(letters.randomElement()!)
            } else {
                code += String(numbers.randomElement()!)
            }
        }
        
        return code
    }
}

struct EventCreationView: View {
    @StateObject private var viewModel = EventCreationViewModel()
    @State private var showingEventCode = false
    @State private var showingTrackPicker = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppColors.background(for: colorScheme).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    eventDetailsSection
                    trackSection
                    createEventButton
                }
                .padding()
            }
        }
        .navigationTitle("Create Event")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingEventCode) {
            Alert(
                title: Text("Event Created"),
                message: Text("Your event code is: \(viewModel.eventCode)"),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4))
                }
            }
        )
        .sheet(isPresented: $showingTrackPicker) {
            TrackPickerView(selectedTrack: $viewModel.selectedTrack, tracks: viewModel.tracks)
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Event Details")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text(for: colorScheme))
            
            TextField("Event Name", text: $viewModel.eventName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(AppColors.text(for: colorScheme))
            
            DatePicker("Event Date", selection: $viewModel.eventDate, displayedComponents: [.date])
                .foregroundColor(AppColors.text(for: colorScheme))
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(10)
    }
    
    private var trackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Track")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text(for: colorScheme))
            
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.tracks.isEmpty {
                Text("No tracks available")
                    .foregroundColor(AppColors.lightText(for: colorScheme))
            } else if let track = viewModel.selectedTrack {
                TrackRow(track: track, isSelected: true)
            } else {
                Text("Select a track")
                    .foregroundColor(AppColors.lightText(for: colorScheme))
            }
            
            Button(action: { showingTrackPicker = true }) {
                Text(viewModel.selectedTrack == nil ? "Select Track" : "Change Track")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.accent(for: colorScheme))
            }
            .disabled(viewModel.tracks.isEmpty)
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme))
        .cornerRadius(10)
    }
    
    private var createEventButton: some View {
        Button(action: {
            viewModel.createEvent()
            showingEventCode = true
        }) {
            Text("Create Event")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.background(for: colorScheme))
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.accent(for: colorScheme))
                .cornerRadius(10)
        }
        .disabled(viewModel.eventName.isEmpty || viewModel.selectedTrack == nil)
        .opacity(viewModel.eventName.isEmpty || viewModel.selectedTrack == nil ? 0.6 : 1)
    }
}

struct TrackPickerView: View {
    @Binding var selectedTrack: Track?
    let tracks: [Track]
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List(tracks) { track in
                TrackRow(track: track, isSelected: selectedTrack?.id == track.id)
                    .onTapGesture {
                        selectedTrack = track
                        presentationMode.wrappedValue.dismiss()
                    }
            }
            .listStyle(PlainListStyle())
            .background(AppColors.background(for: colorScheme))
            .navigationTitle("Select Track")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}



struct EventCreationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventCreationView()
        }
        .preferredColorScheme(.dark)
        
        NavigationView {
            EventCreationView()
        }
        .preferredColorScheme(.light)
    }
}
