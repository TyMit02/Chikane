//
//  LeaderboardView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import SwiftUI
import Firebase
import FirebaseFirestore


class LeaderboardViewModel: ObservableObject {
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var tracks: [Track] = []
    @Published var selectedTrackId: String = ""
    @Published var isLoading: Bool = false
    
    private var db = Firestore.firestore()
    
    init() {
        loadTracksFromJSON()
    }
    
    private func loadTracksFromJSON() {
        guard let url = Bundle.main.url(forResource: "custom_tracks", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error: Unable to load custom_tracks.json")
            return
        }
        
        do {
            let decodedTracks = try JSONDecoder().decode([Track].self, from: data)
            DispatchQueue.main.async {
                self.tracks = decodedTracks
                self.tracks.insert(Track(id: "", name: "All Tracks", country: "", state: "", latitude: 0, longitude: 0, length: 0, startFinishLatitude: 0, startFinishLongitude: 0, type: .roadCourse, configuration: ""), at: 0)
                self.selectedTrackId = ""  // Default to "All Tracks"
            }
        } catch {
            print("Error decoding tracks: \(error)")
        }
    }
    
    func fetchLeaderboard() {
           isLoading = true
           leaderboardEntries.removeAll()  // Clear previous entries
           print("fetchLeaderboard: Starting to fetch leaderboard for track: \(selectedTrackId)")
           
           let query: Query
           if selectedTrackId.isEmpty {
               query = db.collection("globalLeaderboard")
           } else {
               query = db.collection("trackLeaderboards").document(selectedTrackId).collection("entries")
           }
           
           query.order(by: "bestLapTime")
               .limit(to: 100) // Adjust the limit as needed
               .getDocuments { [weak self] (querySnapshot, error) in
                   self?.isLoading = false
                   if let error = error {
                       print("fetchLeaderboard: Error fetching leaderboard: \(error.localizedDescription)")
                       return
                   }
                   
                   guard let documents = querySnapshot?.documents else {
                       print("fetchLeaderboard: No leaderboard documents found")
                       return
                   }
                   
                   print("fetchLeaderboard: Fetched \(documents.count) leaderboard entries")
                   
                   self?.leaderboardEntries = documents.enumerated().compactMap { (index, document) -> LeaderboardEntry? in
                       do {
                           var entry = try document.data(as: LeaderboardEntry.self)
                           entry.position = index + 1
                           return entry
                       } catch {
                           print("Error decoding leaderboard entry: \(error)")
                           return nil
                       }
                   }
                   
                   print("fetchLeaderboard: Processed \(self?.leaderboardEntries.count ?? 0) leaderboard entries")
                   
                   DispatchQueue.main.async {
                       self?.objectWillChange.send()
                   }
               }
       }
   }
struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    trackPickerSection
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.leaderboardEntries.isEmpty {
                        Text("No leaderboard entries found")
                            .foregroundColor(AppColors.lightText)
                    } else {
                        ScrollView {
                            VStack(spacing: 15) {
                                ForEach(viewModel.leaderboardEntries) { entry in
                                    LeaderboardEntryRow(entry: entry)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Track Leaderboards")
        }
        .onAppear {
            print("LeaderboardView - onAppear")
            viewModel.fetchLeaderboard()
        }
    }
    
    private var trackPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Track")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Picker("Select Track", selection: $viewModel.selectedTrackId) {
                ForEach(viewModel.tracks) { track in
                    Text(track.name).tag(track.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .background(AppColors.cardBackground)
            .cornerRadius(10)
            .onChange(of: viewModel.selectedTrackId) { _ in
                viewModel.fetchLeaderboard()
            }
        }
        .padding()
    }
}

    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }



struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
            .preferredColorScheme(.dark)
    }
}
