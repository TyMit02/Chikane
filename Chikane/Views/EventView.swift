//
//  EventView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//


import SwiftUI
import Combine
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct EventView: View {
    let eventCode: String
    @StateObject private var viewModel: EventViewModel
    @State private var showingNewSession = false
    @State private var showingMyResults = false
    @State private var showingEventDetails = false
    @State private var showingChat = false
    
    init(eventCode: String) {
        self.eventCode = eventCode
        print("EventView initialized with event code: \(eventCode)")
        _viewModel = StateObject(wrappedValue: EventViewModel(eventCode: eventCode))
    }
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Error")
                        .font(.title)
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    Text("Event Code: \(eventCode)")
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    VStack(spacing: 30) {
                        eventInfoSection
                        participantsSection
                        quickActionsSection
                        leaderboardSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(viewModel.event?.name ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewSession) {
            NewSessionView(preselectedTrack: viewModel.event?.trackObject, eventCode: eventCode)
        }
        .sheet(isPresented: $showingMyResults) {
            MyResultsView(eventCode: eventCode)
        }
        .sheet(isPresented: $showingEventDetails) {
            EventDetailsView(event: viewModel.event)
        }
        .sheet(isPresented: $showingChat) {
            ChatView(eventCode: eventCode)
        }
    }
    
    private var eventInfoSection: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.event?.name ?? "Event Details Unavailable")
                    .font(AppFonts.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.text)
                
                if let event = viewModel.event {
                    Text(event.date, style: .date)
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.lightText)
                    
                    Text(viewModel.trackName)
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.accent)
                    
                    Text("Event Code: \(event.eventCode)")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.secondary)
                    
                    Text("Organizer: \(viewModel.organizerName)")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.lightText)
                    
                    if !viewModel.isParticipant {
                        Button(action: {
                            viewModel.joinEvent()
                        }) {
                            Text("Join Event")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(AppColors.accent)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Participants")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Text("\(viewModel.participants.count) registered")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
                .transition(.opacity)
                .id("participantCount")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut, value: viewModel.participants.count)
    }
    
    private var quickActionsSection: some View {
          VStack(spacing: 20) {
              Text("Quick Actions")
                  .font(AppFonts.headline)
                  .foregroundColor(AppColors.text)
                  .frame(maxWidth: .infinity, alignment: .leading)
              
              LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                  quickActionButton(title: "Start Session", icon: "flag.checkered", action: { showingNewSession = true })
                  quickActionButton(title: "View My Results", icon: "chart.bar.fill", action: { showingMyResults = true })
                  quickActionButton(title: "Event Details", icon: "info.circle.fill", action: { showingEventDetails = true })
                  quickActionButton(title: "Chat", icon: "message.fill", action: { showingChat = true })
              }
          }
      }
    
    private func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(AppColors.accent)
                Text(title)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.text)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
    }
    
    private var leaderboardSection: some View {
           VStack(spacing: 15) {
               Text("Leaderboard")
                   .font(AppFonts.headline)
                   .foregroundColor(AppColors.text)
                   .frame(maxWidth: .infinity, alignment: .leading)
               
               if viewModel.leaderboardEntries.isEmpty {
                   Text("No leaderboard entries yet")
                       .foregroundColor(AppColors.lightText)
               } else {
                   ForEach(viewModel.leaderboardEntries) { entry in
                       LeaderboardEntryRow(entry: entry)
                           .transition(.opacity.combined(with: .move(edge: .trailing)))
                           .id(entry.id)
                   }
               }
           }
           .animation(.easeInOut, value: viewModel.leaderboardEntries.map { $0.id })
       }
   }

struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack {
            if let position = entry.position {
                Text("\(position)")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 30)
            } else {
                Text("-")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.accent)
                    .frame(width: 30)
            }
            
            VStack(alignment: .leading) {
                Text(entry.driverName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                Text("\(entry.carMake) \(entry.carModel)")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
            }
            
            Spacer()
            
            Text(formatTime(entry.bestLapTime))
                .font(AppFonts.body)
                .foregroundColor(AppColors.accent)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }
}

class EventViewModel: ObservableObject {
    @Published var event: Event?
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var organizerName: String = "Unknown"
    @Published var trackName: String = ""
    @Published var isParticipant: Bool = false
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var participants: [String] = []
    @Published var selectedCarId: String = ""
    @Published var selectedCar: Car?
    
    private let eventCode: String
    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    init(eventCode: String) {
        self.eventCode = eventCode
        print("EventViewModel initialized with event code: \(eventCode)")
        setupListeners()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    private func setupListeners() {
        print("Setting up listeners for event code: \(eventCode)")
        let eventListener = db.collection("events").whereField("eventCode", isEqualTo: eventCode)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching event: \(error.localizedDescription)")
                    self.errorMessage = "Error fetching event: \(error.localizedDescription)"
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("Event document does not exist for code: \(self.eventCode)")
                    self.errorMessage = "Event not found"
                    return
                }
                
                print("Event document exists. Data: \(document.data())")
                
                do {
                    let event = try document.data(as: Event.self)
                    print("Successfully decoded event: \(event)")
                    DispatchQueue.main.async {
                        self.event = event
                        self.participants = event.participants ?? []
                        self.trackName = event.track
                        self.fetchOrganizerName(organizerId: event.organizerId)
                        self.checkParticipation()
                    }
                } catch {
                    print("Error decoding event: \(error)")
                    self.errorMessage = "Error decoding event: \(error.localizedDescription)"
                }
            }
        listeners.append(eventListener)
          
        let leaderboardListener = db.collection("events").document(eventCode).collection("leaderboard")
                  .order(by: "bestLapTime")
                  .addSnapshotListener { [weak self] querySnapshot, error in
                      if let error = error {
                          print("EventViewModel - Error fetching leaderboard: \(error.localizedDescription)")
                          return
                      }
                      
                      guard let documents = querySnapshot?.documents else {
                          print("EventViewModel - No leaderboard documents found for event: \(self?.eventCode ?? "unknown")")
                          return
                      }
                      
                      print("EventViewModel - Fetched \(documents.count) leaderboard entries for event: \(self?.eventCode ?? "unknown")")
                      
                      self?.leaderboardEntries = documents.enumerated().compactMap { (index, document) -> LeaderboardEntry? in
                          do {
                              var entry = try document.data(as: LeaderboardEntry.self)
                              entry.position = index + 1
                              print("EventViewModel - Decoded leaderboard entry: \(entry)")
                              return entry
                          } catch {
                              print("EventViewModel - Error decoding leaderboard entry: \(error)")
                              print("EventViewModel - Document data: \(document.data())")
                              return nil
                          }
                      }
                      
                      print("EventViewModel - Processed \(self?.leaderboardEntries.count ?? 0) leaderboard entries")
                      
                      DispatchQueue.main.async {
                          self?.objectWillChange.send()
                      }
                  }
              listeners.append(leaderboardListener)
          }
      
    func joinEvent() {
           guard let userId = Auth.auth().currentUser?.uid else {
               self.errorMessage = "User not logged in"
               return
           }
           
           db.collection("events").whereField("eventCode", isEqualTo: eventCode).getDocuments { [weak self] (querySnapshot, error) in
               if let error = error {
                   print("Error fetching event: \(error.localizedDescription)")
                   self?.errorMessage = "Error fetching event: \(error.localizedDescription)"
                   return
               }
               
               guard let document = querySnapshot?.documents.first else {
                   print("Event does not exist")
                   self?.errorMessage = "Event does not exist"
                   return
               }
               
               let eventRef = document.reference
               let eventId = document.documentID
               
               eventRef.updateData([
                   "participants": FieldValue.arrayUnion([userId])
               ]) { [weak self] error in
                   if let error = error {
                       print("Error joining event: \(error.localizedDescription)")
                       self?.errorMessage = "Error joining event: \(error.localizedDescription)"
                   } else {
                       // Update user's profile
                       AuthenticationManager.shared.addEventToUserProfile(eventId: eventId) { result in
                           DispatchQueue.main.async {
                               switch result {
                               case .success:
                                   self?.isParticipant = true
                                   if !(self?.participants.contains(userId) ?? false) {
                                       self?.participants.append(userId)
                                   }
                               case .failure(let error):
                                   print("Error updating user profile: \(error.localizedDescription)")
                                   self?.errorMessage = "Error updating user profile: \(error.localizedDescription)"
                               }
                           }
                       }
                   }
               }
           }
       }
    
    func fetchEventData() {
        db.collection("events").document(eventCode).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                do {
                    let event = try document.data(as: Event.self)
                    DispatchQueue.main.async {
                        self?.event = event
                        self?.fetchTrackDetails(trackId: event.trackId)
                        self?.fetchOrganizerName(organizerId: event.organizerId)
                    }
                } catch {
                    print("Error decoding event: \(error)")
                }
            } else {
                print("Event document does not exist")
            }
        }
    }
    
    private func fetchTrackDetails(trackId: String) {
           db.collection("tracks").document(trackId).getDocument { [weak self] (document, error) in
               if let document = document, document.exists {
                   do {
                       let track = try document.data(as: Track.self)
                       DispatchQueue.main.async {
                           self?.event?.trackObject = track
                           self?.trackName = track.name
                       }
                   } catch {
                       print("Error decoding track: \(error)")
                       DispatchQueue.main.async {
                           self?.trackName = self?.event?.track ?? "Unknown Track"
                       }
                   }
               } else {
                   print("Track document does not exist")
                   DispatchQueue.main.async {
                       self?.trackName = self?.event?.track ?? "Unknown Track"
                   }
               }
           }
       }
    
    private func fetchEvent() {
        db.collection("events").document(eventCode).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                do {
                    let event = try document.data(as: Event.self)
                    DispatchQueue.main.async {
                        self?.event = event
                        self?.fetchTrackName(trackId: event.trackId)
                        self?.fetchOrganizerName(organizerId: event.organizerId)
                    }
                } catch {
                    print("Error decoding event: \(error)")
                }
            } else {
                print("Event document does not exist")
            }
        }
    }
    
    private func fetchTrackName(trackId: String) {
        db.collection("tracks").document(trackId).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                let trackName = document.data()?["name"] as? String ?? "Unknown Track"
                DispatchQueue.main.async {
                    self?.trackName = trackName
                }
            }
        }
    }
    
    private func fetchOrganizerName(organizerId: String) {
           db.collection("users").document(organizerId).getDocument { [weak self] (document, error) in
               if let document = document, document.exists {
                   let organizerName = document.data()?["username"] as? String ?? "Unknown Organizer"
                   DispatchQueue.main.async {
                       self?.organizerName = organizerName
                   }
               }
           }
       }
    
    private func checkParticipation() {
           guard let userId = Auth.auth().currentUser?.uid else { return }
           isParticipant = event?.participants?.contains(userId) ?? false
       }
    
    func registerForEvent() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            db.collection("events").document(eventCode).collection("participants").document(userId).setData([:]) { [weak self] error in
                if let error = error {
                    print("Error registering for event: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self?.isParticipant = true
                    }
                }
            }
        }
    
    private func fetchLeaderboard() {
        db.collection("events").document(eventCode).collection("leaderboard")
            .order(by: "bestLapTime")
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents in leaderboard")
                    return
                }
                
                let entries = documents.enumerated().compactMap { (index, document) -> LeaderboardEntry? in
                    do {
                        var entry = try document.data(as: LeaderboardEntry.self)
                        entry.position = index + 1
                        return entry
                    } catch {
                        print("Error decoding leaderboard entry: \(error)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self?.leaderboardEntries = entries
                }
            }
        
        
    }
    
    func startNewSession() {
        // Implement start new session logic
        print("Starting new session")
    }
    
    func viewMyResults() {
        // Implement view my results logic
        print("Viewing my results")
    }
    
    func viewEventDetails() {
        // Implement view event details logic
        print("Viewing event details")
    }
    
    func openEventChat() {
        // Implement open event chat logic
        print("Opening event chat")
    }
}


struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        EventView(eventCode: "ABC123")
            .preferredColorScheme(.dark)
    }
}

struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let driverName: String
    let carMake: String
    let carModel: String
    let bestLapTime: TimeInterval

    // Position is not stored, but calculated when displaying
    var position: Int?

    enum CodingKeys: String, CodingKey {
        case id, driverName, carMake, carModel, bestLapTime
    }
}

struct Event: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let name: String
    let date: Date
    let track: String  // This is the track name or ID from Firestore
    let trackId: String
    let organizerId: String
    let eventCode: String
    var participants: [String]?
    var trackObject: Track?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case date
        case track
        case trackId
        case organizerId
        case eventCode
        case participants
    }

    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.date == rhs.date &&
        lhs.track == rhs.track &&
        lhs.trackId == rhs.trackId &&
        lhs.organizerId == rhs.organizerId &&
        lhs.eventCode == rhs.eventCode &&
        lhs.participants == rhs.participants
    }
}
