struct TelemetryChartView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @State private var selectedMetric = 0
    @State private var selectedLap = 0
    
    var metrics = ["Speed", "Acceleration"]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(0..<metrics.count, id: \.self) { index in
                        Text(metrics[index]).tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("Lap", selection: $selectedLap) {
                    ForEach(0..<viewModel.session.lapTimes.count, id: \.self) { index in
                        Text("Lap \(index + 1)").tag(index)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Chart {
                ForEach(viewModel.telemetryDataForLap(selectedLap, metric: metrics[selectedMetric]), id: \.timestamp) { point in
                    LineMark(
                        x: .value("Time", point.timestamp, unit: .second),
                        y: .value("Value", metricValue(point))
                    )
                    .foregroundStyle(Color.green)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 300)
            
            VStack(alignment: .leading) {
                Text("Lap \(selectedLap + 1)")
                    .font(.headline)
                Text("Time: \(viewModel.formatTime(viewModel.session.lapTimes[selectedLap]))")
                Text("Max \(metrics[selectedMetric]): \(String(format: "%.1f", viewModel.maxValueForLap(selectedLap, metric: metrics[selectedMetric]))) \(metricUnit)")
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private func metricValue(_ point: TelemetryPoint) -> Double {
        switch metrics[selectedMetric] {
        case "Speed":
            return point.speed
        case "Acceleration":
            return point.acceleration
        default:
            return 0
        }
    }
    
    private var metricUnit: String {
        switch metrics[selectedMetric] {
        case "Speed":
            return "km/h"
        case "Acceleration":
            return "G"
        default:
            return ""
        }
    }
}