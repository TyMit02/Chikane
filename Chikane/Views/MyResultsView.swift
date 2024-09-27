//
//  MyResultsView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/22/24.
//


import SwiftUI
import FirebaseFirestore
import Firebase
import FirebaseAuth

struct MyResultsView: View {
    let eventCode: String
    @StateObject private var viewModel: MyResultsViewModel
    
    init(eventCode: String) {
        self.eventCode = eventCode
        _viewModel = StateObject(wrappedValue: MyResultsViewModel(eventCode: eventCode))
    }
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.results.isEmpty {
                Text("No results found")
                    .foregroundColor(AppColors.lightText)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.results) { result in
                            SessionResultView(result: result)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Results")
        .onAppear { viewModel.fetchResults() }
    }
}

struct ResultRow: View {
    let result: SessionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.sessionName)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            HStack {
                Text("Best Lap: \(result.bestLapTime)")
                Spacer()
                Text("Avg Lap: \(result.averageLapTime)")
            }
            .font(AppFonts.subheadline)
            .foregroundColor(AppColors.lightText)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}

class MyResultsViewModel: ObservableObject {
    @Published var results: [SessionResult] = []
    @Published var isLoading = false
    private let eventCode: String
    private let db = Firestore.firestore()
    
    init(eventCode: String) {
        self.eventCode = eventCode
    }
    
    func fetchResults() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        print("Fetching results for event: \(eventCode), user: \(userId)")
        
        db.collection("events").document(eventCode).collection("sessions")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                self?.isLoading = false
                if let error = error {
                    print("Error fetching results: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No session documents found")
                    return
                }
                
                print("Fetched \(documents.count) session documents")
                
                self?.results = documents.compactMap { document in
                    do {
                        let result = try document.data(as: SessionResult.self)
                        print("Decoded session result: \(result.sessionName)")
                        return result
                    } catch {
                        print("Error decoding session result: \(error)")
                        return nil
                    }
                }
                
                print("Processed \(self?.results.count ?? 0) session results")
            }
    }
}

struct SessionResultView: View {
    let result: SessionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.sessionName)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text)
            
            Text("Best Lap: \(result.formattedBestLapTime)")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.accent)
            
            Text("Average Lap: \(result.formattedAverageLapTime)")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
            
            ForEach(Array(result.formattedLapTimes.enumerated()), id: \.element) { index, lapTime in
                HStack {
                    Text("Lap \(index + 1)")
                    Spacer()
                    Text(lapTime)
                        .foregroundColor(lapTime == result.formattedBestLapTime ? .purple : AppColors.text)
                }
                .font(AppFonts.caption)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}

struct SessionResult: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let sessionName: String
    let bestLapTime: TimeInterval
    let averageLapTime: TimeInterval
    let lapTimes: [TimeInterval]
    
    var formattedBestLapTime: String {
        formatTime(bestLapTime)
    }
    
    var formattedAverageLapTime: String {
        formatTime(averageLapTime)
    }
    
    var formattedLapTimes: [String] {
        lapTimes.map { formatTime($0) }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }
}
