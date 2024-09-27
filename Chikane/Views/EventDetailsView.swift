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
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}

class EventDetailsViewModel: ObservableObject {
    @Published var event: Event?
    @Published var organizerName: String = ""
    @Published var participants: [Participant] = []
    private let db = Firestore.firestore()
    
    init(event: Event?) {
        self.event = event
        fetchOrganizerName()
        fetchParticipants()
    }
    
    private func fetchParticipants() {
        guard let participantIds = event?.participants else { return }
        
        for participantId in participantIds {
            db.collection("users").document(participantId).getDocument { [weak self] document, error in
                if let document = document, document.exists,
                   let name = document.data()?["username"] as? String {
                    self?.fetchCarInfo(for: participantId) { carInfo in
                        DispatchQueue.main.async {
                            self?.participants.append(Participant(id: participantId, name: name, carInfo: carInfo))
                        }
                    }
                }
            }
        }
    }
    
    private func fetchCarInfo(for userId: String, completion: @escaping (String) -> Void) {
        db.collection("users").document(userId).collection("cars").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching car info: \(error.localizedDescription)")
                completion("Unknown Car")
                return
            }
            
            guard let document = snapshot?.documents.first else {
                completion("No Car")
                return
            }
            
            let make = document.data()["make"] as? String ?? "Unknown"
            let model = document.data()["model"] as? String ?? "Model"
            completion("\(make) \(model)")
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
}

struct Participant: Identifiable {
    let id: String
    let name: String
    let carInfo: String
}
