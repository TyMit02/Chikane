 class SessionDetailViewModel: ObservableObject {
        @Published var session: Session
        @Published var region: MKCoordinateRegion
        @Published var mapAnnotations: [MapAnnotation] = []
        @Published var currentSpeed: Double = 0
        @Published var currentAcceleration: Double = 0
        @Published var currentLateralG: Double = 0
        
        private var playbackTimer: Timer?
        private var currentPlaybackIndex: Int = 0
        var cancellables = Set<AnyCancellable>()
        
        init(session: Session) {
            self.session = session
            let initialCoordinate = session.telemetryData.first?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            self.region = MKCoordinateRegion(center: initialCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.mapAnnotations = session.telemetryData.map { MapAnnotation(coordinate: $0.coordinate) }
            
            // Initialize current values
            if let firstPoint = session.telemetryData.first {
                self.currentSpeed = firstPoint.speed
                self.currentAcceleration = firstPoint.acceleration
            }
        }
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: session.date)
        }
        
        func formatTime(_ time: TimeInterval) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
            return String(format: "%d:%02d.%03d", minutes, seconds, milliseconds)
        }
        
        var bestLapMaxSpeed: Double {
            session.telemetryData.map { $0.speed }.max() ?? 0
        }
        
        var bestLapAvgSpeed: Double {
            let speeds = session.telemetryData.map { $0.speed }
            return speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        }
        
        var bestLapMaxGForce: Double {
            let bestLapIndex = session.lapTimes.firstIndex(of: session.bestLapTime) ?? 0
            return maxValueForLap(bestLapIndex, metric: "Acceleration")
        }
        
        var bestLapCornerCount: Int {
            let bestLapIndex = session.lapTimes.firstIndex(of: session.bestLapTime) ?? 0
            let bestLapData = telemetryDataForLap(bestLapIndex, metric: "Acceleration")
            let threshold = 0.5 // Adjust as needed
            var cornerCount = 0
            var inCorner = false
            
            for point in bestLapData {
                if point.acceleration > threshold && !inCorner {
                    cornerCount += 1
                    inCorner = true
                } else if point.acceleration <= threshold {
                    inCorner = false
                }
            }
            
            return cornerCount
        }
        
        func speedDataForLap(_ lapIndex: Int) -> [SpeedPoint] {
            let lapData = telemetryDataForLap(lapIndex, metric: "Speed")
            return lapData.enumerated().map { index, point in
                SpeedPoint(distance: Double(index) * 10, speed: point.speed)
            }
        }
        
        func maxSpeedForLap(_ lapIndex: Int) -> Double {
            speedDataForLap(lapIndex).map { $0.speed }.max() ?? 0
        }
        
        func telemetryDataForLap(_ lapIndex: Int, metric: String) -> [TelemetryPoint] {
            guard lapIndex < session.lapTimes.count else { return [] }
            
            let lapStartTime: TimeInterval = session.lapTimes.prefix(lapIndex).reduce(0, +)
            let lapEndTime = lapStartTime + session.lapTimes[lapIndex]
            
            return session.telemetryData.filter {
                $0.timestamp.timeIntervalSince(session.date) >= lapStartTime &&
                $0.timestamp.timeIntervalSince(session.date) < lapEndTime
            }
        }
        
        func maxValueForLap(_ lapIndex: Int, metric: String) -> Double {
            let data = telemetryDataForLap(lapIndex, metric: metric)
            switch metric {
            case "Speed": return data.map { $0.speed }.max() ?? 0
            case "Acceleration": return data.map { $0.acceleration }.max() ?? 0
            default: return 0
            }
        }
        
        var trackOutline: [CGPoint] {
            let minLat = session.telemetryData.map { $0.latitude }.min() ?? 0
            let maxLat = session.telemetryData.map { $0.latitude }.max() ?? 0
            let minLon = session.telemetryData.map { $0.longitude }.min() ?? 0
            let maxLon = session.telemetryData.map { $0.longitude }.max() ?? 0
            
            let normalizePoint: (Double, Double) -> CGPoint = { lat, lon in
                let x = (lon - minLon) / (maxLon - minLon) * 300
                let y = (lat - minLat) / (maxLat - minLat) * 300
                return CGPoint(x: x, y: y)
            }
            
            return session.telemetryData.map { normalizePoint($0.latitude, $0.longitude) }
        }
        
        func pathForLap(_ lapIndex: Int) -> [CGPoint] {
            let lapData = telemetryDataForLap(lapIndex, metric: "")
            guard !lapData.isEmpty else { return [] }
            
            let minLat = lapData.map { $0.latitude }.min()!
            let maxLat = lapData.map { $0.latitude }.max()!
            let minLon = lapData.map { $0.longitude }.min()!
            let maxLon = lapData.map { $0.longitude }.max()!
            
            let normalizePoint: (Double, Double) -> CGPoint = { lat, lon in
                let x = (lon - minLon) / (maxLon - minLon) * 300
                let y = (1 - (lat - minLat) / (maxLat - minLat)) * 300 // Invert y-axis
                return CGPoint(x: x, y: y)
            }
            
            return lapData.map { normalizePoint($0.latitude, $0.longitude) }
        }
        
        func positionForLap(_ lapIndex: Int, progress: Double) -> CLLocationCoordinate2D {
            let lapData = telemetryDataForLap(lapIndex, metric: "")
            let index = Int(Double(lapData.count) * progress)
            guard index < lapData.count else { return CLLocationCoordinate2D() }
            let point = lapData[index]
            return point.coordinate
        }
        
        func speedForLap(_ lapIndex: Int, progress: Double) -> Double {
            let lapData = telemetryDataForLap(lapIndex, metric: "")
            let index = Int(Double(lapData.count) * progress)
            guard index < lapData.count else { return 0 }
            return lapData[index].speed
        }
        
        func startPlayback() {
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updatePlayback()
            }
        }
        
        func stopPlayback() {
            playbackTimer?.invalidate()
            playbackTimer = nil
        }
        
        func seekToProgress(_ progress: Double) {
            currentPlaybackIndex = Int(Double(session.telemetryData.count) * progress)
            updatePlayback()
        }
        
        private func updatePlayback() {
            guard currentPlaybackIndex < session.telemetryData.count else {
                stopPlayback()
                return
            }
            
            let point = session.telemetryData[currentPlaybackIndex]
            updateMapAnnotations(with: point.coordinate)
            currentSpeed = point.speed
            currentAcceleration = point.acceleration
            
            currentPlaybackIndex += 1
        }
        
        private func updateMapAnnotations(with coordinate: CLLocationCoordinate2D? = nil) {
            if let coordinate = coordinate {
                mapAnnotations = [MapAnnotation(coordinate: coordinate)]
            } else {
                mapAnnotations = session.telemetryData.map { MapAnnotation(coordinate: $0.coordinate) }
            }
        }
        
        struct MapAnnotation: Identifiable {
            let id = UUID()
            let coordinate: CLLocationCoordinate2D
        }
        
    }
}