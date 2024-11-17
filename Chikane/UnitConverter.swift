import Foundation

class UnitConverter {
    static let shared = UnitConverter()
    
    func convertSpeed(_ speed: Double, from: UnitSystem, to: UnitSystem) -> Double {
        switch (from, to) {
        case (.metric, .imperial):
            return speed * 0.621371 // km/h to mph
        case (.imperial, .metric):
            return speed * 1.60934 // mph to km/h
        default:
            return speed
        }
    }
    
    func convertDistance(_ distance: Double, from: UnitSystem, to: UnitSystem) -> Double {
        switch (from, to) {
        case (.metric, .imperial):
            return distance * 0.621371 // km to miles
        case (.imperial, .metric):
            return distance * 1.60934 // miles to km
        default:
            return distance
        }
    }
    
    func speedUnit(for system: UnitSystem) -> String {
        system == .metric ? "km/h" : "mph"
    }
    
    func distanceUnit(for system: UnitSystem) -> String {
        system == .metric ? "km" : "mi"
    }
}