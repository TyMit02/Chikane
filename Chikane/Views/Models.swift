//
//  UserSettings.swift
//  Chikane
//
//  Created by Ty Mitchell on 11/12/24.
//


// First, let's create a separate file called Models.swift to hold our shared types:
// Models.swift
import Foundation

struct UserSettings: Codable, Equatable {
    var pushNotificationsEnabled: Bool = true
    var darkModeEnabled: Bool = true
    var preferredUnits: UnitSystem = .metric
    var autoDetectLaps: Bool = true
    var voiceAnnouncementsEnabled: Bool = false
    var dataRefreshFrequency: DataRefreshFrequency = .thirty
    var shareDataWithFriends: Bool = false
    var allowAnonymousUsageData: Bool = true
    var obdWifiHost: String = "192.168.0.10"
    var obdWifiPort: UInt16 = 35000
    var obdAutoDetectPort: Bool = true
}

enum UnitSystem: String, Codable {
    case metric, imperial
}

enum DataRefreshFrequency: String, Codable {
    case fifteen, thirty, hourly
}

// Then update UserProfileViewModel.swift with these fixes:

@MainActor // Add this attribute to the whole class
class UserProfileViewModel: ObservableObject {
    // ... other properties ...
    
    private func refreshData() {
        Task {
            await fetchUserData() // Remove viewModel reference
        }
    }
    
    func updateBestLapTime(trackId: String, trackName: String, lapTime: TimeInterval) {
        Task { @MainActor in // Change to use Task with MainActor
            do {
                guard let userId = supabaseService.currentUser?.id.uuidString,
                      let carId = cars.first?.id else { return }
                
                let leaderboardEntry = PostgresInsert([
                    "track_id": trackId,
                    "user_id": userId,
                    "car_id": carId,
                    "lap_time": lapTime
                ])
                
                try await supabaseService.supabase.database
                    .from("leaderboards")
                    .upsert(leaderboardEntry)
                    .execute()
                
                try await self.fetchBestLapTimes() // Remove MainActor.run
            } catch {
                print("Error updating best lap time: \(error.localizedDescription)")
            }
        }
    }
    
    func addCar(_ car: Car) {
        Task { @MainActor in // Change to use Task with MainActor
            do {
                guard let userId = supabaseService.currentUser?.id.uuidString else { return }
                
                let carData = PostgresInsert([
                    "user_id": userId,
                    "make": car.make,
                    "model": car.model,
                    "year": car.year,
                    "trim": car.trim as Any,
                    "horsepower": car.horsepower as Any,
                    "weight": car.weight as Any,
                    "torque": car.torque as Any,
                    "notes": car.notes as Any
                ])
                
                try await supabaseService.supabase.database
                    .from("cars")
                    .insert(carData)
                    .execute()
                
                try await self.fetchCars() // Remove MainActor.run
            } catch {
                print("Error adding car: \(error.localizedDescription)")
            }
        }
    }
}