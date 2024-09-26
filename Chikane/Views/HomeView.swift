
//
//  HomeView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/15/24.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingNewSession = false
    @State private var showingJoinEvent = false
    @State private var showingManageCars = false
    @State private var showingLeaderboard = false
    @State private var showingSessionHistory = false
    @State private var showingEventCreation = false
    @State private var eventCode = ""
    @State private var isShowingJoinEventAlert = false
    @State private var tempEventCode = ""

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 30) {
                        welcomeSection
                        quickActionsSection
                        currentEventsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Chikane")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UserProfileView()) {
                        Image(systemName: "person.circle")
                            .foregroundColor(AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingNewSession) {
                NewSessionView()
            }
            .sheet(isPresented: $showingJoinEvent) {
                EventView(eventCode: eventCode)
            }
            .sheet(isPresented: $showingManageCars) {
                ManageCarsView()
            }
            .sheet(isPresented: $showingLeaderboard) {
                LeaderboardView()
            }
            .sheet(isPresented: $showingSessionHistory) {
                SessionHistoryView()
            }
            .sheet(isPresented: $showingEventCreation){
                EventCreationView()
            }
            .alert("Join Event", isPresented: $isShowingJoinEventAlert) {
                TextField("Event Code", text: $tempEventCode)
                Button("Cancel", role: .cancel) { }
                Button("Join") {
                    if !tempEventCode.isEmpty {
                        eventCode = tempEventCode
                        showingJoinEvent = true
                    }
                }
            } message: {
                Text("Enter the event code")
            }
        }
        .onAppear {
            viewModel.fetchUserData()
        }
    }
    
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome, \(viewModel.username)")
                .font(AppFonts.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.text)
            
            Text("Ready to hit the track?")
                .font(AppFonts.title1)
                .foregroundColor(AppColors.lightText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var quickActionsSection: some View {
            VStack(spacing: 20) {
                Text("Quick Actions")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    quickActionButton(title: "New Session", icon: "flag.checkered", action: { showingNewSession = true })
                    quickActionButton(title: "Join Event", icon: "person.3.fill", action: { isShowingJoinEventAlert = true })
                    quickActionButton(title: "Manage Cars", icon: "car.fill", action: { showingManageCars = true })
                    quickActionButton(title: "Leaderboard", icon: "list.number", action: { showingLeaderboard = true })
                    quickActionButton(title: "Session History", icon: "clock.arrow.circlepath", action: { showingSessionHistory = true })
                    quickActionButton(title: "Host an Event", icon: "flag.and.flag.filled.crossed", action: {showingEventCreation = true})
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
    
  
    
    private var currentEventsSection: some View {
            VStack(spacing: 15) {
                Text("Current Events")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if viewModel.userEvents.isEmpty {
                    Text("You are not participating in any events.")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.lightText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.userEvents) { event in
                        NavigationLink(destination: EventView(eventCode: event.eventCode)) {
                            UserEventRow(event: event)
                        }
                    }
                }
            }
        }
    }

    struct UserEventRow: View {
        let event: Event
        
        var body: some View {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(AppColors.accent)
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(event.name)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text)
                    Text(event.track)
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.lightText)
                }
                
                Spacer()
                
                Text(formatDate(event.date))
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(10)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }



struct ActivityRow: View {
    let activity: RecentActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(AppColors.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(activity.title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.text)
                Text(activity.subtitle)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.lightText)
            }
            
            Spacer()
            
            Text(activity.timeAgo)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}

class HomeViewModel: ObservableObject {
    @Published var username: String = "Driver"
    @Published var userEvents: [Event] = []
    
    private let authManager = AuthenticationManager.shared
    private let db = Firestore.firestore()
    
    func fetchUserData() {
           authManager.fetchUserData { [weak self] result in
               DispatchQueue.main.async {
                   switch result {
                   case .success(let userProfile):
                       self?.username = userProfile.username
                       if let participatingEvents = userProfile.participatingEvents, !participatingEvents.isEmpty {
                           self?.fetchUserEvents(participatingEvents: participatingEvents)
                       } else {
                           // If there are no participating events, clear the userEvents array
                           self?.userEvents = []
                       }
                   case .failure(let error):
                       print("Error fetching user data: \(error.localizedDescription)")
                       // In case of an error, set a default username
                       self?.username = "Driver"
                   }
               }
           }
       }
       
    
    private func fetchUserEvents(participatingEvents: [String]) {
        guard !participatingEvents.isEmpty else {
            self.userEvents = []
            return
        }
        
        db.collection("events")
            .whereField(FieldPath.documentID(), in: participatingEvents)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Error fetching user events: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No events found")
                    return
                }
                
                self?.userEvents = documents.compactMap { document -> Event? in
                    try? document.data(as: Event.self)
                }
                
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
    }
}

struct RecentActivity: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let timeAgo: String
}



struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
