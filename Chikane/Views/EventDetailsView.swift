//
//  EventDetailsView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//

import SwiftUI
import FirebaseFirestore
import Firebase
import FirebaseAuth

struct EventDetailsView: View {
    @ObservedObject var viewModel: EventDetailsViewModel
    
    init(event: Event?) {
        viewModel = EventDetailsViewModel(event: event)
    }
    
    var body: some View {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        eventInfoSection
                        participantsSection
                        leaderboardSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Event Details")
        }
    
    private var eventInfoSection: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.event?.name ?? "Event Details")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.text)
                Text("Date: \(viewModel.event?.date.formatted() ?? "N/A")")
                Text("Track: \(viewModel.event?.trackObject?.name ?? viewModel.event?.track ?? "N/A")")
                Text("Organizer: \(viewModel.organizerName)")
                Text("Event Code: \(viewModel.event?.eventCode ?? "N/A")")
            }
            .foregroundColor(AppColors.lightText)
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
    
    private var participantsSection: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("Participants")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                
                ForEach(viewModel.participants) { participant in
                    HStack {
                        Text(participant.name)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.text)
                        Spacer()
                        Text(participant.carInfo)
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.lightText)
                    }
                }
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
    
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leaderboard")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            ForEach(viewModel.leaderboardEntries) { entry in
                LeaderboardEntryRow(entry: entry)
            }
        }
    }
}

class EventDetailsViewModel: ObservableObject {
    @Published var event: Event?
    @Published var organizerName: String = ""
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var participants: [Participant] = []
    private let db = Firestore.firestore()
    
    init(event: Event?) {
        self.event = event
        fetchOrganizerName()
        fetchLeaderboard()
        fetchParticipants()
    }
    
    private func fetchParticipants() {
            guard let participantIds = event?.participants else { return }
            
            for participantId in participantIds {
                db.collection("users").document(participantId).getDocument { [weak self] document, error in
                    if let document = document, document.exists,
                       let name = document.data()?["username"] as? String,
                       let carId = document.data()?["currentCar"] as? String {
                        self?.fetchCarInfo(for: carId) { carInfo in
                            DispatchQueue.main.async {
                                self?.participants.append(Participant(id: participantId, name: name, carInfo: carInfo))
                            }
                        }
                    }
                }
            }
        }
        
        private func fetchCarInfo(for carId: String, completion: @escaping (String) -> Void) {
            db.collection("cars").document(carId).getDocument { document, error in
                if let document = document, document.exists,
                   let make = document.data()?["make"] as? String,
                   let model = document.data()?["model"] as? String {
                    completion("\(make) \(model)")
                } else {
                    completion("Unknown Car")
                }
            }
        }
        
    
    private func fetchOrganizerName() {
        guard let organizerId = event?.organizerId else { return }
        db.collection("users").document(organizerId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                self?.organizerName = document.data()?["username"] as? String ?? "Unknown"
            }
        }
    }
    
    private func fetchLeaderboard() {
        guard let eventCode = event?.eventCode else { return }
        db.collection("events").document(eventCode).collection("leaderboard")
            .order(by: "bestLapTime")
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching leaderboard: \(error.localizedDescription)")
                    return
                }
                
                self?.leaderboardEntries = snapshot?.documents.compactMap { document in
                    try? document.data(as: LeaderboardEntry.self)
                } ?? []
            }
    }
}

struct Participant: Identifiable {
    let id: String
    let name: String
    let carInfo: String
}
