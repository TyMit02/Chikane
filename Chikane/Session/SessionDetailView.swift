//
//  SessionDetailView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/21/24.
//


import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: Session
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                lapTimesSection
                chartSection
                statisticsSection
                weatherSection
                notesSection
            }
            .padding()
        }
        .navigationTitle(session.name)
        .background(AppColors.background.edgesIgnoringSafeArea(.all))
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(session.track.name)
                .font(.title2)
                .foregroundColor(AppColors.text)
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(AppColors.lightText)
            Text("Car: \(session.carId)")
                .font(.subheadline)
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var lapTimesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lap Times")
                .font(.headline)
                .foregroundColor(AppColors.text)
            ForEach(Array(session.lapTimes.enumerated()), id: \.offset) { index, lapTime in
                HStack {
                    Text("Lap \(index + 1)")
                        .foregroundColor(AppColors.lightText)
                    Spacer()
                    Text(formatTime(lapTime))
                        .foregroundColor(lapTimeColor(lapTime))
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lap Time Progression")
                .font(.headline)
                .foregroundColor(AppColors.text)
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
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(AppColors.text)
            HStack {
                StatisticView(title: "Best Lap", value: formatTime(session.bestLapTime))
                Spacer()
                StatisticView(title: "Average Lap", value: formatTime(session.averageLapTime))
            }
            HStack {
                StatisticView(title: "Total Distance", value: String(format: "%.2f km", session.totalDistance / 1000))
                Spacer()
                StatisticView(title: "Average Speed", value: String(format: "%.2f km/h", session.averageSpeed))
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weather Conditions")
                .font(.headline)
                .foregroundColor(AppColors.text)
            HStack {
                StatisticView(title: "Condition", value: session.weather.condition)
                Spacer()
                StatisticView(title: "Temperature", value: String(format: "%.1f°C", session.weather.temperature))
            }
            HStack {
                StatisticView(title: "Humidity", value: String(format: "%.1f%%", session.weather.humidity))
                Spacer()
                StatisticView(title: "Wind", value: "\(session.weather.windSpeed) km/h \(session.weather.windDirection)")
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(AppColors.text)
            Text(session.notes ?? "No notes for this session.")
                .foregroundColor(AppColors.lightText)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.date)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }
    
    private func lapTimeColor(_ lapTime: TimeInterval) -> Color {
        if lapTime == session.bestLapTime {
            return AppColors.successGreen
        } else if lapTime < session.averageLapTime {
            return AppColors.highlightBlue
        } else {
            return AppColors.lightText
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.lightText)
            Text(value)
                .font(.body)
                .foregroundColor(AppColors.text)
        }
    }
}
