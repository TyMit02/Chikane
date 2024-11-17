//
//  Event.swift
//  Chikane
//
//  Created by Ty Mitchell on 10/20/24.
//


import Foundation
import FirebaseFirestore

public struct Event: Identifiable, Codable, Equatable {
    @DocumentID public var id: String?
    public let name: String
    public let date: Date
    public let track: String
    public let trackId: String
    public let organizerId: String
    public let eventCode: String
    public var participants: [String]?
    public var trackObject: Track?
    
    enum CodingKeys: String, CodingKey {
        case id, name, date, track, trackId, organizerId, eventCode, participants
    }
    
    public static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.date == rhs.date &&
        lhs.track == rhs.track &&
        lhs.trackId == rhs.trackId &&
        lhs.organizerId == rhs.organizerId &&
        lhs.eventCode == rhs.eventCode &&
        lhs.participants == rhs.participants
    }
}

public struct LeaderboardEntry: Identifiable, Codable {
    public let id: String
    public let driverName: String
    public let carMake: String
    public let carModel: String
    public let bestLapTime: TimeInterval
    public var position: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, driverName, carMake, carModel, bestLapTime
    }
}