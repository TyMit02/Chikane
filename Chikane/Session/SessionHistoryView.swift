//
//  SessionHistoryView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/21/24.
//


import SwiftUI
import Combine

struct SessionHistoryView: View {
    @StateObject private var viewModel = SessionHistoryViewModel()
    @State private var showingFilterOptions = false
    @State private var selectedSession: Session?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sessions) { session in
                    SessionRowView(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
                if viewModel.canLoadMore {
                    ProgressView()
                        .onAppear {
                            viewModel.loadMoreSessions()
                        }
                }
            }
            .navigationTitle("Session History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilterOptions = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilterOptions) {
                FilterView(filter: $viewModel.filter)
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
        .onAppear {
            viewModel.loadSessions()
        }
    }
}

struct SessionRowView: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.name)
                .font(.headline)
            Text(session.track.name)
                .font(.subheadline)
            HStack {
                Text(session.formattedDate)
                Spacer()
                Text("Best: \(formatTime(session.bestLapTime))")
                    .foregroundColor(.green)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }
}

class SessionHistoryViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var filter: SessionFilter = SessionFilter()
    @Published var canLoadMore = true
    
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private let pageSize = 20
    
    func loadSessions() {
        print("Loading initial sessions")
        fetchSessions(limit: pageSize)
    }
    
    func loadMoreSessions() {
        print("Loading more sessions")
        fetchSessions(limit: pageSize * (currentPage + 1))
    }
    
    private func fetchSessions(limit: Int) {
        guard let userId = AuthenticationManager.shared.user?.uid else {
            print("Error: No user logged in")
            return
        }
        
        print("Fetching sessions for user: \(userId), limit: \(limit)")
        SessionManager.shared.fetchSessions(for: userId, limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.handleCompletion(completion)
                },
                receiveValue: { [weak self] sessions in
                    self?.handleReceivedSessions(sessions, limit: limit)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleCompletion(_ completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            print("Session fetch completed successfully")
        case .failure(let error):
            print("Error loading sessions: \(error.localizedDescription)")
        }
    }
    
    private func handleReceivedSessions(_ sessions: [Session], limit: Int) {
        print("Received \(sessions.count) sessions")
        self.sessions = sessions
        self.canLoadMore = sessions.count == limit
        self.currentPage = limit / pageSize
        print("Updated sessions count: \(self.sessions.count)")
    }
}

struct SessionFilter {
    var track: Track?
    var car: Car?
    var dateRange: ClosedRange<Date>?
    var weatherCondition: String?
}

struct FilterView: View {
    @Binding var filter: SessionFilter
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                // Implement filter options here
            }
            .navigationTitle("Filter Sessions")
            .navigationBarItems(trailing: Button("Apply") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
