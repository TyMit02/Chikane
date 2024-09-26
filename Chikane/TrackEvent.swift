//
//  TrackEvent.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//



import SwiftUI
import Combine

// MARK: - Models

public struct TrackEvent: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let date: Date
    public let location: String
    public let organizerName: String
    public let eventType: String
    public let registrationUrl: String?
    
    public init(id: String, name: String, date: Date, location: String, organizerName: String, eventType: String, registrationUrl: String?) {
        self.id = id
        self.name = name
        self.date = date
        self.location = location
        self.organizerName = organizerName
        self.eventType = eventType
        self.registrationUrl = registrationUrl
    }
}

// MARK: - TrackEventService

public class TrackEventService {
    public static let shared = TrackEventService()
    private init() {}
    
    public func fetchUpcomingEvents() -> AnyPublisher<[TrackEvent], Error> {
        // In a real implementation, this would make an API call or fetch data from a local database
        // For now, we'll return some sample data
        let sampleEvents = [
            TrackEvent(id: "1", name: "Summer Speed Challenge", date: Date().addingTimeInterval(86400 * 30), location: "Laguna Seca", organizerName: "Speed Club", eventType: "Time Trial", registrationUrl: "https://example.com/event1"),
            TrackEvent(id: "2", name: "Autumn Time Attack", date: Date().addingTimeInterval(86400 * 60), location: "Road Atlanta", organizerName: "Track Masters", eventType: "Time Attack", registrationUrl: "https://example.com/event2"),
            TrackEvent(id: "3", name: "Winter Drift Series", date: Date().addingTimeInterval(86400 * 90), location: "Sonoma Raceway", organizerName: "Drift Kings", eventType: "Drifting", registrationUrl: "https://example.com/event3")
        ]
        
        return Just(sampleEvents)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - ViewModel

public class TrackEventsViewModel: ObservableObject {
    @Published public var upcomingEvents: [TrackEvent] = []
    @Published public var isLoading = false
    @Published public var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {}
    
    public func fetchUpcomingEvents() {
        isLoading = true
        error = nil
        
        TrackEventService.shared.fetchUpcomingEvents()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error
                    print("Error fetching events: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] events in
                self?.upcomingEvents = events.sorted { $0.date < $1.date }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Views

public struct UpcomingEventsView: View {
    @StateObject private var viewModel = TrackEventsViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Track Events")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.accent)
            } else if viewModel.upcomingEvents.isEmpty {
                Text("No upcoming events found")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.lightText)
            } else {
                ForEach(viewModel.upcomingEvents) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .cornerRadius(10)
        .onAppear {
            viewModel.fetchUpcomingEvents()
        }
    }
}

public struct EventRow: View {
    let event: TrackEvent
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(event.name)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.text)
            Text(event.location)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.lightText)
            Text(formattedDate(event.date))
                .font(AppFonts.caption)
                .foregroundColor(AppColors.accent)
            if let url = event.registrationUrl, let registrationUrl = URL(string: url) {
                Link("Register", destination: registrationUrl)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

class TrackDatabase {
    static let shared = TrackDatabase()
     var tracksCache: [Track] = []
    
    private init() {
        loadTracksFromJSON()
    }
    
    private func loadTracksFromJSON() {
        guard let url = Bundle.main.url(forResource: "custom_tracks", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error: Unable to load custom_tracks.json")
            return
        }
        
        do {
            tracksCache = try JSONDecoder().decode([Track].self, from: data)
            print("Loaded \(tracksCache.count) tracks from JSON")
        } catch {
            print("Error decoding tracks: \(error)")
        }
    }
    
    func getAllTracks() -> [Track] {
        return tracksCache
    }
    
    func getTrack(by id: String) -> Track? {
        return tracksCache.first { $0.id == id }
    }
    
    func searchTracks(query: String) -> [Track] {
        let lowercasedQuery = query.lowercased()
        return tracksCache.filter { track in
            track.name.lowercased().contains(lowercasedQuery) ||
            track.country.lowercased().contains(lowercasedQuery) ||
            track.state.lowercased().contains(lowercasedQuery)
        }
    }
    
    func getTracksByState(_ state: String) -> [Track] {
        return tracksCache.filter { $0.state == state }
    }
    
    func getTracksByCountry(_ country: String) -> [Track] {
        return tracksCache.filter { $0.country == country }
    }
    
    func getUniqueStates() -> [String] {
        return Array(Set(tracksCache.map { $0.state })).sorted()
    }
    
    func getUniqueCountries() -> [String] {
        return Array(Set(tracksCache.map { $0.country })).sorted()
    }
}
