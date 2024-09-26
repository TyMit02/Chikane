//
//  LapTimesView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import SwiftUI
import Charts
import Combine

struct LapTimesView: View {
    @StateObject private var viewModel = LapTimesViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        SessionRow(session: session)
                    }
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            Text("Date").tag(LapTimesViewModel.SortOption.date)
                            Text("Track").tag(LapTimesViewModel.SortOption.track)
                            Text("Best Lap").tag(LapTimesViewModel.SortOption.bestLap)
                        }
                        Toggle("Ascending", isOn: $viewModel.sortAscending)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchSessions()
        }
    }
}

struct SessionRow: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(session.name)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            Text(session.track.name)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
            Text("Best: \(formatTime(session.bestLapTime))")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.accent)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}



struct LapTimeChartView: View {
    let session: Session
    
    var body: some View {
        VStack {
            Text("Lap Time Progression")
                .font(AppFonts.headline)
            
            Chart {
                ForEach(Array(session.lapTimes.enumerated()), id: \.offset) { index, lapTime in
                    LineMark(
                        x: .value("Lap", index + 1),
                        y: .value("Time", lapTime)
                    )
                    .foregroundStyle(AppColors.accent)
                    
                    PointMark(
                        x: .value("Lap", index + 1),
                        y: .value("Time", lapTime)
                    )
                    .foregroundStyle(AppColors.accent)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .frame(height: 300)
            .padding()
        }
    }
}

class LapTimesViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var sortAscending = true
    @Published var sortOption: SortOption = .date
    private var cancellables = Set<AnyCancellable>()

    enum SortOption {
        case date, track, bestLap
    }
    
    func fetchSessions() {
           guard let userId = AuthenticationManager.shared.user?.uid else {
               print("Error: No authenticated user")
               return
           }
           
           SessionManager.shared.fetchSessions(for: userId)
               .receive(on: DispatchQueue.main)
               .sink { completion in
                   switch completion {
                   case .finished:
                       break
                   case .failure(let error):
                       print("Error fetching sessions: \(error.localizedDescription)")
                       // Handle error (e.g., show an alert)
                   }
               } receiveValue: { [weak self] fetchedSessions in
                   self?.sessions = fetchedSessions
                   self?.sortSessions()
               }
               .store(in: &cancellables)
       }
    
    func sortSessions() {
            sessions.sort { session1, session2 in
                switch sortOption {
                case .date:
                    return sortAscending ? session1.date < session2.date : session1.date > session2.date
                case .track:
                    return sortAscending ? session1.track.name < session2.track.name : session1.track.name > session2.track.name
                case .bestLap:
                    return sortAscending ? session1.bestLapTime < session2.bestLapTime : session1.bestLapTime > session2.bestLapTime
                }
            }
        }
    }
