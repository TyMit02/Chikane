import SwiftUI
import Charts

struct LapComparisonView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @State private var selectedLap1 = 0
    @State private var selectedLap2 = 1
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Picker("Lap 1", selection: $selectedLap1) {
                    ForEach(0..<viewModel.session.lapTimes.count, id: \.self) { index in
                        Text("Lap \(index + 1)").tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("Lap 2", selection: $selectedLap2) {
                    ForEach(0..<viewModel.session.lapTimes.count, id: \.self) { index in
                        Text("Lap \(index + 1)").tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Chart {
                ForEach(viewModel.speedDataForLap(selectedLap1), id: \.distance) { point in
                    LineMark(
                        x: .value("Distance", point.distance),
                        y: .value("Speed", point.speed)
                    )
                    .foregroundStyle(Color.blue)
                }
                ForEach(viewModel.speedDataForLap(selectedLap2), id: \.distance) { point in
                    LineMark(
                        x: .value("Distance", point.distance),
                        y: .value("Speed", point.speed)
                    )
                    .foregroundStyle(Color.orange)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 300)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Lap \(selectedLap1 + 1)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("Time: \(viewModel.formatTime(viewModel.session.lapTimes[selectedLap1]))")
                    Text("Max Speed: \(String(format: "%.1f km/h", viewModel.maxSpeedForLap(selectedLap1)))")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Lap \(selectedLap2 + 1)")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("Time: \(viewModel.formatTime(viewModel.session.lapTimes[selectedLap2]))")
                    Text("Max Speed: \(String(format: "%.1f km/h", viewModel.maxSpeedForLap(selectedLap2)))")
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
}