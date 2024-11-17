import Foundation
import WeatherKit
import CoreLocation

class WeatherKitService {
    static let shared = WeatherKitService()
    private let weatherService = WeatherService.shared

    private init() {}

    func getCurrentWeather(for location: CLLocation) async throws -> WeatherCondition {
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather

        return WeatherCondition(
            condition: current.condition.description,
            temperature: current.temperature.value,
            humidity: current.humidity * 100, // Convert to percentage
            windSpeed: current.wind.speed.value,
            windDirection: current.wind.direction.description
        )
    }
}