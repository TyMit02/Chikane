import MapKit

class CornerAnnotation: NSObject, MKAnnotation {
    // Required MKAnnotation property
    let coordinate: CLLocationCoordinate2D
    
    // Optional MKAnnotation properties
    var title: String? {
        return "Corner \(cornerNumber)"
    }
    
    var subtitle: String? {
        return String(format: "Entry: %.1f km/h\nExit: %.1f km/h", entrySpeed * 3.6, exitSpeed * 3.6)
    }
    
    // Custom properties
    let cornerNumber: Int
    let entrySpeed: Double
    let exitSpeed: Double
    let radius: Double
    let angle: Double
    
    // Initialize from CornerAnalysis
    init(cornerAnalysis: CornerAnalysis) {
        self.coordinate = cornerAnalysis.location
        self.cornerNumber = cornerAnalysis.number
        self.entrySpeed = cornerAnalysis.entrySpeed
        self.exitSpeed = cornerAnalysis.exitSpeed
        self.radius = cornerAnalysis.cornerRadius
        self.angle = cornerAnalysis.angleChange
        super.init()
    }
    
    // Convenience initializer for direct values (if needed)
    init(coordinate: CLLocationCoordinate2D, entrySpeed: Double, exitSpeed: Double, radius: Double, angle: Double) {
        self.coordinate = coordinate
        self.cornerNumber = Int(abs(angle / 45)) + 1
        self.entrySpeed = entrySpeed
        self.exitSpeed = exitSpeed
        self.radius = radius
        self.angle = angle
        super.init()
    }
}
