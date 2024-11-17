import Foundation
import CoreLocation

struct WatkinsGlenSimulation {
    static let coordinates: [(CLLocationCoordinate2D, Double)] = [
        (CLLocationCoordinate2D(latitude: 42.336697, longitude: -76.927517), 120), // Start/Finish
        (CLLocationCoordinate2D(latitude: 42.336853, longitude: -76.928697), 100), // Turn 1
        (CLLocationCoordinate2D(latitude: 42.337375, longitude: -76.929351), 80),  // Esses
        (CLLocationCoordinate2D(latitude: 42.338103, longitude: -76.929769), 90),
        (CLLocationCoordinate2D(latitude: 42.338831, longitude: -76.929941), 110),
        (CLLocationCoordinate2D(latitude: 42.339559, longitude: -76.929855), 130),
        (CLLocationCoordinate2D(latitude: 42.340287, longitude: -76.929512), 140), // Back straight
        (CLLocationCoordinate2D(latitude: 42.341015, longitude: -76.928912), 150),
        (CLLocationCoordinate2D(latitude: 42.341743, longitude: -76.928054), 160),
        (CLLocationCoordinate2D(latitude: 42.342471, longitude: -76.926938), 170),
        (CLLocationCoordinate2D(latitude: 42.342699, longitude: -76.925651), 130), // Bus Stop
        (CLLocationCoordinate2D(latitude: 42.342427, longitude: -76.924364), 110),
        (CLLocationCoordinate2D(latitude: 42.341699, longitude: -76.923334), 140), // Chute
        (CLLocationCoordinate2D(latitude: 42.340971, longitude: -76.922561), 150),
        (CLLocationCoordinate2D(latitude: 42.340243, longitude: -76.922046), 120), // Toe of the Boot
        (CLLocationCoordinate2D(latitude: 42.339515, longitude: -76.921789), 90),
        (CLLocationCoordinate2D(latitude: 42.338787, longitude: -76.921789), 80),  // Heel of the Boot
        (CLLocationCoordinate2D(latitude: 42.338059, longitude: -76.922046), 100),
        (CLLocationCoordinate2D(latitude: 42.337331, longitude: -76.922561), 120),
        (CLLocationCoordinate2D(latitude: 42.336603, longitude: -76.923334), 140), // Out of the Boot
        (CLLocationCoordinate2D(latitude: 42.336375, longitude: -76.924364), 150),
        (CLLocationCoordinate2D(latitude: 42.336147, longitude: -76.925651), 160),
        (CLLocationCoordinate2D(latitude: 42.336375, longitude: -76.926938), 140), // Final turn
        (CLLocationCoordinate2D(latitude: 42.336697, longitude: -76.927517), 130)  // Back to Start/Finish
    ]
    
    static var track: Track {
        Track(id: "wgn001", 
              name: "Watkins Glen International",
              country: "United States",
              state: "New York",
              latitude: 42.336697,
              longitude: -76.927517,
              length: 5.43,
              startFinishLatitude: 42.336697,
              startFinishLongitude: -76.927517,
              type: .roadCourse,
              configuration: "Grand Prix Circuit")
    }
}