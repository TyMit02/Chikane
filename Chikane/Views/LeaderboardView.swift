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
        fetchTracks()
    }
    
    func fetchTracks() {
        isLoading = true
        db.collection("tracks").getDocuments(source: .default) { [weak self] (querySnapshot, error) in
            self?.isLoading = false
            if let error = error {
                print("Error fetching tracks: \(error.localizedDescription)")
                return
            }
            
            self?.tracks = querySnapshot?.documents.compactMap { document in
                let data = document.data()
                return Track(
                    id: document.documentID,
                    name: data["name"] as? String ?? "",
                    country: data["country"] as? String ?? "",
                    state: data["state"] as? String ?? "",
                    latitude: Double(data["latitude"] as? String ?? "0") ?? 0,
                    longitude: Double(data["longitude"] as? String ?? "0") ?? 0,
                    length: data["length"] as? Double ?? 0,
                    startFinishLatitude: Double(data["startFinishLatitude"] as? String ?? "0") ?? 0,
                    startFinishLongitude: Double(data["startFinishLongitude"] as? String ?? "0") ?? 0,
                    type: Track.TrackType(rawValue: data["type"] as? String ?? "") ?? .roadCourse,
                    configuration: data["configuration"] as? String ?? ""
                )
            } ?? []
            
            // Add "All Tracks" option
            self?.tracks.insert(Track(
                id: "",
                name: "All Tracks",
                country: "",
                state: "",
                latitude: 0,
                longitude: 0,
                length: 0,
                startFinishLatitude: 0,
                startFinishLongitude: 0,
                type: .roadCourse,
                configuration: ""
            ), at: 0)
        }
    }
    
    func fetchLeaderboard() {
          isLoading = true
          var query: Query = db.collection("leaderboard")
          
          if !selectedTrackId.isEmpty {
              query = query.whereField("trackId", isEqualTo: selectedTrackId)
          }
          
          query.order(by: "bestLapTime").limit(to: 100).getDocuments { [weak self] (querySnapshot, error) in
              self?.isLoading = false
              if let error = error {
                  print("Error fetching leaderboard: \(error.localizedDescription)")
                  return
              }
              
              self?.leaderboardEntries = querySnapshot?.documents.compactMap { document in
                  try? document.data(as: LeaderboardEntry.self)
              } ?? []
          }
      }
  }

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                trackPicker
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.leaderboardEntries.isEmpty {
                    Text("No entries found")
                        .foregroundColor(AppColors.lightText)
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Leaderboard")
        }
        .onAppear {
            viewModel.fetchLeaderboard()
        }
    }
    
    private var trackPicker: some View {
           Picker("Select Track", selection: $viewModel.selectedTrackId) {
               ForEach(viewModel.tracks) { track in
                   Text(track.name).tag(track.id)
               }
           }
           .pickerStyle(MenuPickerStyle())
           .padding()
           .onChange(of: viewModel.selectedTrackId) { _ in
               viewModel.fetchLeaderboard()
           }
       }
       
       private var leaderboardList: some View {
           List {
               ForEach(Array(viewModel.leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                   LeaderboardRow(entry: entry, rank: index + 1)
               }
           }
           .listStyle(PlainListStyle())
       }
   }

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(entry.driverName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                Text("\(entry.carMake) \(entry.carModel)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.lightText)
            }
            
            Spacer()
            
            Text(entry.bestLapTime)
                .font(AppFonts.body)
                .foregroundColor(AppColors.accent)
        }
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
