struct CornerAnalysisView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCorner: CornerAnalysis?
    @State private var showingFullMetrics = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Track Map with Corner Overview
            ZStack {
                RacingLineMapView(viewModel: viewModel, mapType: .constant(.satellite))
                    .frame(height: 200)
                    .cornerRadius(10)
                
                if let selectedCorner = selectedCorner {
                    // Corner Highlight Overlay
                    CornerHighlight(corner: selectedCorner)
                }
            }
            
            // Corner Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(viewModel.cornerAnalysis) { corner in
                        CornerCard(
                            corner: corner,
                            isSelected: selectedCorner?.id == corner.id,
                            metrics: viewModel.getCornerMetrics(for: corner)
                        )
                        .onTapGesture {
                            withAnimation {
                                selectedCorner = corner
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)
            
            if let corner = selectedCorner {
                // Detailed Corner Analysis
                VStack(spacing: 15) {
                    // Speed Trace
                    SpeedChart(viewModel: viewModel, corner: corner)
                        .frame(height: 200)
                    
                    // Key Metrics Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        MetricView(
                            title: "Entry Speed",
                            value: String(format: "%.1f", corner.entrySpeed),
                            unit: "mph",
                            trend: viewModel.getSpeedTrend(for: corner, phase: .entry)
                        )
                        
                        MetricView(
                            title: "Apex Speed",
                            value: String(format: "%.1f", corner.apexSpeed),
                            unit: "mph",
                            trend: viewModel.getSpeedTrend(for: corner, phase: .apex)
                        )
                        
                        MetricView(
                            title: "Exit Speed",
                            value: String(format: "%.1f", corner.exitSpeed),
                            unit: "mph",
                            trend: viewModel.getSpeedTrend(for: corner, phase: .exit)
                        )
                        
                        MetricView(
                            title: "Min Radius",
                            value: String(format: "%.0f", corner.minimumRadius),
                            unit: "m",
                            trend: nil
                        )
                        
                        MetricView(
                            title: "G-Force",
                            value: String(format: "%.1f", viewModel.getMaxGForce(for: corner)),
                            unit: "G",
                            trend: nil
                        )
                        
                        MetricView(
                            title: "Line Dev",
                            value: String(format: "%.1f", corner.idealLineDeviation),
                            unit: "m",
                            trend: viewModel.getLineDeviationTrend(for: corner)
                        )
                    }
                    
                    // Performance Insights
                    if let insights = viewModel.getCornerInsights(for: corner) {
                        InsightView(insights: insights)
                    }
                }
                .padding()
                .background(AppColors.cardBackground(for: colorScheme))
                .cornerRadius(10)
            }
        }
    }
}

struct CornerCard: View {
    let corner: CornerAnalysis
    let isSelected: Bool
    let metrics: CornerMetrics
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Corner \(corner.number)")
                .font(AppFonts.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.1f", metrics.consistencyScore))%")
                        .font(AppFonts.caption)
                        .foregroundColor(consistencyColor)
                    Text("Consistency")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.lightText(for: colorScheme))
                }
                
                Spacer()
                
                Text("\(String(format: "%.1f", metrics.timeDelta))s")
                    .font(AppFonts.subheadline)
                    .foregroundColor(deltaColor)
            }
        }
        .padding()
        .frame(width: 150)
        .background(isSelected ? AppColors.accent(for: colorScheme).opacity(0.2) : AppColors.cardBackground(for: colorScheme))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? AppColors.accent(for: colorScheme) : Color.clear, lineWidth: 2)
        )
    }
    
    private var consistencyColor: Color {
        switch metrics.consistencyScore {
        case 90...: return .green
        case 75...: return .yellow
        default: return .red
        }
    }
    
    private var deltaColor: Color {
        metrics.timeDelta < 0 ? .green : .red
    }
}

struct SpeedChart: View {
    let viewModel: SessionDetailViewModel
    let corner: CornerAnalysis
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Chart {
            ForEach(viewModel.getSpeedTrace(for: corner)) { point in
                LineMark(
                    x: .value("Distance", point.distance),
                    y: .value("Speed", point.speed)
                )
                .foregroundStyle(AppColors.accent(for: colorScheme))
            }
            
            // Markers for entry, apex, and exit
            RuleMark(x: .value("Entry", viewModel.getCornerPhaseDistance(for: corner, phase: .entry)))
                .foregroundStyle(.green)
            
            RuleMark(x: .value("Apex", viewModel.getCornerPhaseDistance(for: corner, phase: .apex)))
                .foregroundStyle(.yellow)
            
            RuleMark(x: .value("Exit", viewModel.getCornerPhaseDistance(for: corner, phase: .exit)))
                .foregroundStyle(.red)
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct InsightView: View {
    let insights: [CornerInsight]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insights")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.text(for: colorScheme))
            
            ForEach(insights) { insight in
                HStack(spacing: 10) {
                    Image(systemName: insight.icon)
                        .foregroundColor(insight.color)
                    
                    Text(insight.message)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.text(for: colorScheme))
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground(for: colorScheme).opacity(0.5))
        .cornerRadius(8)
    }
}