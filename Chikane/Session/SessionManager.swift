//
//  SessionManager.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/17/24.
//


import Foundation
import FirebaseFirestore
import Combine

class SessionManager {
    static let shared = SessionManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func fetchSessions(for userId: String, limit: Int = 20) -> AnyPublisher<[Session], Error> {
        return Future { promise in
            print("Fetching sessions for user: \(userId), limit: \(limit)")
            self.db.collection("sessions")
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching sessions: \(error.localizedDescription)")
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found for user: \(userId)")
                        promise(.failure(NSError(domain: "SessionManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No documents found"])))
                        return
                    }
                    
                    print("Found \(documents.count) session documents")
                    let sessions = documents.compactMap { document -> Session? in
                        do {
                            let session = try document.data(as: Session.self)
                            print("Successfully decoded session: \(session.id ?? "No ID")")
                            return session
                        } catch {
                            print("Error decoding session document: \(error.localizedDescription)")
                            // Print the document data for debugging
                            print("Document data: \(document.data())")
                            return nil
                        }
                    }
                    print("Successfully decoded \(sessions.count) sessions")
                    promise(.success(sessions))
                }
        }.eraseToAnyPublisher()
    }
    
    func saveSession(_ session: Session) -> AnyPublisher<Void, Error> {
        return Future { promise in
            do {
                print("Attempting to save session: \(session.id ?? "No ID")")
                _ = try self.db.collection("sessions").addDocument(from: session) { error in
                    if let error = error {
                        print("Error saving session: \(error.localizedDescription)")
                        promise(.failure(error))
                    } else {
                        print("Session saved successfully: \(session.id ?? "No ID")")
                        promise(.success(()))
                    }
                }
            } catch {
                print("Error encoding session for save: \(error.localizedDescription)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchSessionDetails(sessionId: String) -> AnyPublisher<Session, Error> {
        return Future { promise in
            self.db.collection("sessions").document(sessionId).getDocument { snapshot, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let document = snapshot, document.exists,
                      let session = Session.fromFirestore(document) else {
                    promise(.failure(NSError(domain: "SessionManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Session not found"])))
                    return
                }
                
                promise(.success(session))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchSessionsForTrack(trackId: String, userId: String) -> AnyPublisher<[Session], Error> {
        return Future { promise in
            self.db.collection("sessions")
                .whereField("userId", isEqualTo: userId)
                .whereField("trackId", isEqualTo: trackId)
                .order(by: "date", descending: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.failure(NSError(domain: "SessionManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No documents found"])))
                        return
                    }
                    
                    let sessions = documents.compactMap { Session.fromFirestore($0) }
                    promise(.success(sessions))
                }
        }.eraseToAnyPublisher()
    }
    
    func deleteSession(sessionId: String) -> AnyPublisher<Void, Error> {
        return Future { promise in
            self.db.collection("sessions").document(sessionId).delete { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
}

struct Session: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let name: String
    let date: Date
    let track: Track
    let carId: String
    let lapTimes: [Double]
    let sectorTimes: [[Double]]
    let bestLapTime: Double
    let averageLapTime: Double
    let weather: WeatherCondition
    let totalDistance: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let notes: String?
    let fuelConsumption: Double?
    let tireCompound: String?
    let trackTemperature: Double?
    let airTemperature: Double?

    enum CodingKeys: String, CodingKey {
        case id, userId, name, date, track, carId, lapTimes, sectorTimes, bestLapTime, averageLapTime, weather, totalDistance, averageSpeed, maxSpeed, notes, fuelConsumption, tireCompound, trackTemperature, airTemperature
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

   
    init(id: String? = nil,
             userId: String,
             name: String,
             date: Date,
             track: Track,
             carId: String,
             lapTimes: [Double],
             sectorTimes: [[Double]],
             bestLapTime: Double,
             averageLapTime: Double,
             weather: WeatherCondition,
             totalDistance: Double,
             averageSpeed: Double,
             maxSpeed: Double,
             notes: String? = nil,
             fuelConsumption: Double? = nil,
             tireCompound: String? = nil,
             trackTemperature: Double? = nil,
             airTemperature: Double? = nil) {
            self.id = id
            self.userId = userId
            self.name = name
            self.date = date
            self.track = track
            self.carId = carId
            self.lapTimes = lapTimes
            self.sectorTimes = sectorTimes
            self.bestLapTime = bestLapTime
            self.averageLapTime = averageLapTime
            self.weather = weather
            self.totalDistance = totalDistance
            self.averageSpeed = averageSpeed
            self.maxSpeed = maxSpeed
            self.notes = notes
            self.fuelConsumption = fuelConsumption
            self.tireCompound = tireCompound
            self.trackTemperature = trackTemperature
            self.airTemperature = airTemperature
        }
    }


struct WeatherCondition: Codable {
    let condition: String
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
}

extension Session {
    static func fromFirestore(_ snapshot: DocumentSnapshot) -> Session? {
        guard let data = snapshot.data(),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let date = (data["date"] as? Timestamp)?.dateValue(),
              let trackData = data["track"] as? [String: Any],
              let carId = data["carId"] as? String,
              let lapTimes = data["lapTimes"] as? [Double],
              let sectorTimes = data["sectorTimes"] as? [[Double]],
              let bestLapTime = data["bestLapTime"] as? Double,
              let averageLapTime = data["averageLapTime"] as? Double,
              let weatherData = data["weather"] as? [String: Any],
              let totalDistance = data["totalDistance"] as? Double,
              let averageSpeed = data["averageSpeed"] as? Double,
              let maxSpeed = data["maxSpeed"] as? Double else {
            return nil
        }
        
        let track = Track(
            id: trackData["id"] as? String ?? "",
            name: trackData["name"] as? String ?? "",
            country: trackData["country"] as? String ?? "",
            state: trackData["state"] as? String ?? "",
            latitude: Double(trackData["latitude"] as? String ?? "") ?? 0,
            longitude: Double(trackData["longitude"] as? String ?? "") ?? 0,
            length: trackData["length"] as? Double ?? 0,
            startFinishLatitude: Double(trackData["startFinishLatitude"] as? String ?? "") ?? 0,
            startFinishLongitude: Double(trackData["startFinishLongitude"] as? String ?? "") ?? 0,
            type: Track.TrackType(rawValue: trackData["type"] as? String ?? "") ?? .roadCourse,
            configuration: trackData["configuration"] as? String ?? ""
        )
        
        let weather = WeatherCondition(
            condition: weatherData["condition"] as? String ?? "",
            temperature: weatherData["temperature"] as? Double ?? 0.0,
            humidity: weatherData["humidity"] as? Double ?? 0.0,
            windSpeed: weatherData["windSpeed"] as? Double ?? 0.0,
            windDirection: weatherData["windDirection"] as? String ?? ""
        )
        
        return Session(
            id: snapshot.documentID,
            userId: userId,
            name: name,
            date: date,
            track: track,
            carId: carId,
            lapTimes: lapTimes,
            sectorTimes: sectorTimes,
            bestLapTime: bestLapTime,
            averageLapTime: averageLapTime,
            weather: weather,
            totalDistance: totalDistance,
            averageSpeed: averageSpeed,
            maxSpeed: maxSpeed,
            notes: data["notes"] as? String,
            fuelConsumption: data["fuelConsumption"] as? Double,
            tireCompound: data["tireCompound"] as? String,
            trackTemperature: data["trackTemperature"] as? Double,
            airTemperature: data["airTemperature"] as? Double
        )
    }
}

extension SessionManager {
    func calculateProgressionForTrack(trackId: String, userId: String) -> AnyPublisher<[ProgressionPoint], Error> {
        return fetchSessionsForTrack(trackId: trackId, userId: userId)
            .map { sessions -> [ProgressionPoint] in
                let sortedSessions = sessions.sorted { $0.date < $1.date }
                return sortedSessions.map { ProgressionPoint(date: $0.date, bestLapTime: $0.bestLapTime) }
            }
            .eraseToAnyPublisher()
    }
    
    func calculateAverageConditionsForTrack(trackId: String, userId: String) -> AnyPublisher<TrackConditions, Error> {
        return fetchSessionsForTrack(trackId: trackId, userId: userId)
            .map { sessions -> TrackConditions in
                let totalSessions = Double(sessions.count)
                let sumTemperature = sessions.reduce(0) { $0 + $1.weather.temperature }
                let sumHumidity = sessions.reduce(0) { $0 + $1.weather.humidity }
                let sumWindSpeed = sessions.reduce(0) { $0 + $1.weather.windSpeed }
                
                return TrackConditions(
                    averageTemperature: sumTemperature / totalSessions,
                    averageHumidity: sumHumidity / totalSessions,
                    averageWindSpeed: sumWindSpeed / totalSessions
                )
            }
            .eraseToAnyPublisher()
    }
    
    func findPersonalBests(userId: String) -> AnyPublisher<[TrackPersonalBest], Error> {
        return fetchSessions(for: userId, limit: 1000) // Adjust limit as needed
            .map { sessions -> [TrackPersonalBest] in
                let groupedSessions = Dictionary(grouping: sessions, by: { $0.track.id })
                return groupedSessions.compactMap { trackId, trackSessions in
                    guard let bestSession = trackSessions.min(by: { $0.bestLapTime < $1.bestLapTime }),
                          let track = trackSessions.first?.track else { return nil }
                    return TrackPersonalBest(
                        track: track,
                        bestLapTime: bestSession.bestLapTime,
                        date: bestSession.date
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}

struct ProgressionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let bestLapTime: TimeInterval
}

struct TrackConditions {
    let averageTemperature: Double
    let averageHumidity: Double
    let averageWindSpeed: Double
}

struct TrackPersonalBest: Identifiable {
    let id = UUID()
    let track: Track
    let bestLapTime: TimeInterval
    let date: Date
}
