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
        
        db.collection("events").document(eventCode)
            .collection("results").whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                self?.isLoading = false
                if let error = error {
                    print("Error fetching results: \(error.localizedDescription)")
                    return
                }
                
                self?.results = snapshot?.documents.compactMap { document in
                    try? document.data(as: SessionResult.self)
                } ?? []
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
            
            Text("Best Lap: \(result.bestLapTime)")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.accent)
            
            Text("Average Lap: \(result.averageLapTime)")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.lightText)
            
            ForEach(Array(result.lapTimes.enumerated()), id: \.element) { index, lapTime in
                HStack {
                    Text("Lap \(index + 1)")
                    Spacer()
                    Text(lapTime)
                        .foregroundColor(lapTime == result.bestLapTime ? .purple : AppColors.text)
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
    let bestLapTime: String
    let averageLapTime: String
    let lapTimes: [String]
}
