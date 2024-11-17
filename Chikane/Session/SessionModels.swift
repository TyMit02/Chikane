//
//  Session.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/28/24.
//


import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

public struct Session: Identifiable, Codable {
    @DocumentID public var id: String?
    public let userId: String
    public let trackId: String
    public let trackName: String
    public let date: Date
    public let lapTimes: [Double]
    public let bestLapTime: Double
    public let totalLaps: Int

    // Optional fields that might not be present in all documents
    public var name: String?
    public var carId: String?
    public var sectorTimes: [[Double]]?
    public var averageLapTime: Double?
    public var weather: WeatherCondition?
    public var totalDistance: Double?
    public var averageSpeed: Double?
    public var maxSpeed: Double?
    public var notes: String?
    public var fuelConsumption: Double?
    public var tireCompound: String?
    public var trackTemperature: Double?
    public var airTemperature: Double?

    public var formattedBestLapTime: String {
        formatTime(bestLapTime)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
    }
}

public struct WeatherCondition: Codable {
    public let condition: String
    public let temperature: Double
    public let humidity: Double
    public let windSpeed: Double
    public let windDirection: String
    
    public init(condition: String, temperature: Double, humidity: Double, windSpeed: Double, windDirection: String) {
        self.condition = condition
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
    }
}

extension Session {
    public static func fromFirestore(_ document: QueryDocumentSnapshot) -> Session? {
        do {
            let data = document.data()
            let userId = data["userId"] as? String ?? ""
            let trackId = data["trackId"] as? String ?? ""
            let trackName = data["trackName"] as? String ?? ""
            let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
            let lapTimes = data["lapTimes"] as? [Double] ?? []
            let bestLapTime = data["bestLapTime"] as? Double ?? 0
            let totalLaps = data["totalLaps"] as? Int ?? 0

            var session = Session(
                id: document.documentID,
                userId: userId,
                trackId: trackId,
                trackName: trackName,
                date: date,
                lapTimes: lapTimes,
                bestLapTime: bestLapTime,
                totalLaps: totalLaps
            )

            // Optional fields
            session.name = data["name"] as? String
            session.carId = data["carId"] as? String
            session.sectorTimes = data["sectorTimes"] as? [[Double]]
            session.averageLapTime = data["averageLapTime"] as? Double
            session.totalDistance = data["totalDistance"] as? Double
            session.averageSpeed = data["averageSpeed"] as? Double
            session.maxSpeed = data["maxSpeed"] as? Double
            session.notes = data["notes"] as? String
            session.fuelConsumption = data["fuelConsumption"] as? Double
            session.tireCompound = data["tireCompound"] as? String
            session.trackTemperature = data["trackTemperature"] as? Double
            session.airTemperature = data["airTemperature"] as? Double

            if let weatherData = data["weather"] as? [String: Any] {
                session.weather = WeatherCondition(
                    condition: weatherData["condition"] as? String ?? "",
                    temperature: weatherData["temperature"] as? Double ?? 0,
                    humidity: weatherData["humidity"] as? Double ?? 0,
                    windSpeed: weatherData["windSpeed"] as? Double ?? 0,
                    windDirection: weatherData["windDirection"] as? String ?? ""
                )
            }

            return session
        } catch {
            print("Error decoding session: \(error)")
            return nil
        }
    }
}