//
//  InteractiveTrackMapView.swift
//  Chikane
//
//  Created by Ty Mitchell on 10/12/24.
//


import SwiftUI

struct InteractiveTrackMapView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @State private var selectedLap = 0
    @State private var sliderValue: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Track outline
                Path { path in
                    path.addLines(viewModel.trackOutline)
                }
                .stroke(Color.gray, lineWidth: 2)
                
                // Lap path
                Path { path in
                    path.addLines(viewModel.pathForLap(selectedLap))
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Current position
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .position(viewModel.positionForLap(selectedLap, progress: sliderValue))
            }
            .frame(width: 300, height: 300)
            .background(Color.black)
            
            Slider(value: $sliderValue, in: 0...1, step: 0.01)
            
            Picker("Lap", selection: $selectedLap) {
                ForEach(0..<viewModel.session.lapTimes.count, id: \.self) { index in
                    Text("Lap \(index + 1)").tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            VStack(alignment: .leading) {
                Text("Lap \(selectedLap + 1)")
                    .font(.headline)
                Text("Time: \(viewModel.formatTime(viewModel.session.lapTimes[selectedLap]))")
                Text("Speed: \(String(format: "%.1f km/h", viewModel.speedForLap(selectedLap, progress: sliderValue)))")
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}